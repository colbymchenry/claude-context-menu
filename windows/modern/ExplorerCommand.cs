using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;

namespace ClaudeCode.ShellExtension
{
    // ---------------------------------------------------------------------------
    //  COM interface imports — vtable order must match the Windows SDK headers
    // ---------------------------------------------------------------------------

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("a08ce4d0-fa25-44ab-b57c-c7b1c323e0b9")]
    internal interface IExplorerCommand
    {
        [PreserveSig] int GetTitle(IntPtr psiItemArray, [MarshalAs(UnmanagedType.LPWStr)] out string ppszName);
        [PreserveSig] int GetIcon(IntPtr psiItemArray, [MarshalAs(UnmanagedType.LPWStr)] out string ppszIcon);
        [PreserveSig] int GetToolTip(IntPtr psiItemArray, [MarshalAs(UnmanagedType.LPWStr)] out string ppszInfotip);
        [PreserveSig] int GetCanonicalName(out Guid pguidCommandName);
        [PreserveSig] int GetState(IntPtr psiItemArray, [MarshalAs(UnmanagedType.Bool)] bool fOkToBeSlow, out uint pCmdState);
        [PreserveSig] int Invoke(IntPtr psiItemArray, IntPtr pbc);
        [PreserveSig] int GetFlags(out uint pFlags);
        [PreserveSig] int EnumSubCommands(out IntPtr ppEnum);
    }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("b63ea76d-1f85-456f-a19c-48159efa858b")]
    internal interface IShellItemArray
    {
        [PreserveSig] int BindToHandler(IntPtr pbc, ref Guid bhid, ref Guid riid, out IntPtr ppvOut);
        [PreserveSig] int GetPropertyStore(int flags, ref Guid riid, out IntPtr ppv);
        [PreserveSig] int GetPropertyDescriptionList(IntPtr keyType, ref Guid riid, out IntPtr ppv);
        [PreserveSig] int GetAttributes(uint attribFlags, uint sfgaoMask, out uint psfgaoAttribs);
        [PreserveSig] int GetCount(out uint pdwNumItems);
        [PreserveSig] int GetItemAt(uint dwIndex, out IntPtr ppsi);
        [PreserveSig] int EnumItems(out IntPtr ppenumShellItems);
    }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe")]
    internal interface IShellItem
    {
        [PreserveSig] int BindToHandler(IntPtr pbc, ref Guid bhid, ref Guid riid, out IntPtr ppv);
        [PreserveSig] int GetParent(out IntPtr ppsi);
        [PreserveSig] int GetDisplayName(uint sigdnName, [MarshalAs(UnmanagedType.LPWStr)] out string ppszName);
        [PreserveSig] int GetAttributes(uint sfgaoMask, out uint psfgaoAttribs);
        [PreserveSig] int Compare(IntPtr psi, uint hint, out int piOrder);
    }

    // ---------------------------------------------------------------------------
    //  Base class — shared logic for both context menu entries
    // ---------------------------------------------------------------------------

    public abstract class ClaudeCommandBase : IExplorerCommand
    {
        protected abstract string Title { get; }
        protected abstract string ClaudeArgs { get; }
        protected abstract Guid CommandGuid { get; }

        private const uint SIGDN_FILESYSPATH = 0x80058000;
        private const int S_OK = 0;
        private const int E_NOTIMPL = unchecked((int)0x80004001);

        public int GetTitle(IntPtr psiItemArray, out string ppszName)
        {
            ppszName = Title;
            return S_OK;
        }

        public int GetIcon(IntPtr psiItemArray, out string ppszIcon)
        {
            ppszIcon = "claude.exe";
            return S_OK;
        }

        public int GetToolTip(IntPtr psiItemArray, out string ppszInfotip)
        {
            ppszInfotip = Title;
            return S_OK;
        }

        public int GetCanonicalName(out Guid pguidCommandName)
        {
            pguidCommandName = CommandGuid;
            return S_OK;
        }

        public int GetState(IntPtr psiItemArray, bool fOkToBeSlow, out uint pCmdState)
        {
            pCmdState = 0; // ECS_ENABLED
            return S_OK;
        }

        public int GetFlags(out uint pFlags)
        {
            pFlags = 0;
            return S_OK;
        }

        public int EnumSubCommands(out IntPtr ppEnum)
        {
            ppEnum = IntPtr.Zero;
            return E_NOTIMPL;
        }

        public int Invoke(IntPtr psiItemArrayPtr, IntPtr pbc)
        {
            try
            {
                string path = GetFolderPath(psiItemArrayPtr);
                if (!string.IsNullOrEmpty(path))
                {
                    ProcessStartInfo psi;
                    if (IsInPath("wt.exe"))
                    {
                        psi = new ProcessStartInfo
                        {
                            FileName = "wt.exe",
                            Arguments = string.Format("-d \"{0}\" cmd /k \"{1}\"", path, ClaudeArgs),
                            UseShellExecute = true
                        };
                    }
                    else
                    {
                        psi = new ProcessStartInfo
                        {
                            FileName = "cmd.exe",
                            Arguments = string.Format("/k \"cd /d \"{0}\" && {1}\"", path, ClaudeArgs),
                            UseShellExecute = true
                        };
                    }
                    Process.Start(psi);
                }
            }
            catch { }
            return S_OK;
        }

        private static bool IsInPath(string exe)
        {
            var pathVar = Environment.GetEnvironmentVariable("PATH");
            if (pathVar == null) return false;
            foreach (var dir in pathVar.Split(Path.PathSeparator))
            {
                try { if (File.Exists(Path.Combine(dir.Trim(), exe))) return true; }
                catch { }
            }
            return false;
        }

        private static string GetFolderPath(IntPtr psiItemArrayPtr)
        {
            if (psiItemArrayPtr == IntPtr.Zero)
                return null;

            try
            {
                var itemArray = (IShellItemArray)Marshal.GetObjectForIUnknown(psiItemArrayPtr);
                try
                {
                    uint count;
                    if (itemArray.GetCount(out count) != S_OK || count == 0)
                        return null;

                    IntPtr shellItemPtr;
                    if (itemArray.GetItemAt(0, out shellItemPtr) != S_OK)
                        return null;

                    try
                    {
                        var shellItem = (IShellItem)Marshal.GetObjectForIUnknown(shellItemPtr);
                        try
                        {
                            string path;
                            shellItem.GetDisplayName(SIGDN_FILESYSPATH, out path);
                            return path;
                        }
                        finally { Marshal.ReleaseComObject(shellItem); }
                    }
                    finally { Marshal.Release(shellItemPtr); }
                }
                finally { Marshal.ReleaseComObject(itemArray); }
            }
            catch { return null; }
        }
    }

    // ---------------------------------------------------------------------------
    //  "Open with Claude Code" — starts a new claude session
    // ---------------------------------------------------------------------------

    [ComVisible(true)]
    [Guid("E3C4A0D1-B5F2-4C67-8A9E-1D2F3B4C5E60")]
    public sealed class OpenClaudeCommand : ClaudeCommandBase
    {
        protected override string Title => "Open with Claude Code";
        protected override string ClaudeArgs => "claude";
        protected override Guid CommandGuid => new Guid("E3C4A0D1-B5F2-4C67-8A9E-1D2F3B4C5E60");
    }

    // ---------------------------------------------------------------------------
    //  "Resume Chat with Claude" — opens the interactive session picker
    // ---------------------------------------------------------------------------

    [ComVisible(true)]
    [Guid("E3C4A0D1-B5F2-4C67-8A9E-1D2F3B4C5E61")]
    public sealed class ResumeClaudeCommand : ClaudeCommandBase
    {
        protected override string Title => "Resume Chat with Claude";
        protected override string ClaudeArgs => "claude --resume";
        protected override Guid CommandGuid => new Guid("E3C4A0D1-B5F2-4C67-8A9E-1D2F3B4C5E61");
    }
}
