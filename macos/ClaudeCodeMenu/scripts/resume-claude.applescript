on run {inputPath}
	tell application "Terminal"
		activate
		set targetDir to quoted form of inputPath
		do script "cd " & targetDir & " && claude --resume"
	end tell
end run
