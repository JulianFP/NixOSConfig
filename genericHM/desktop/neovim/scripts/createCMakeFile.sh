#!/usr/bin/env bash
#cmake file
printf "# Set minimum Cmake version\ncmake_minimum_required(VERSION 3.11)\n# Start project and set its name\nproject(%s LANGUAGES CXX)\n# Add executable\nadd_executable(%s %s)\n" "$1" "$1" "$2" >CMakeLists.txt

# vimspector file
#printf "{\n  \"configurations\": {\n    \"Launch\": {\n      \"adapter\": \"vscode-cpptools\",\n      \"filetypes\": [ \"cpp\", \"c\", \"cc\" ], // optional\n      \"configuration\": {\n        \"request\": \"launch\",\n        \"program\": \"\${workspaceRoot}/buildDebug/$1\",\n        \"cwd\": \"\${workspaceRoot}\",\n        \"externalConsole\": true,\n        \"MIMode\": \"gdb\",\n        \"setupCommands\": [\n          {\n            \"description\": \"Enable pretty-printing for gdb\",\n            \"text\": \"-enable-pretty-printing\",\n            \"ignoreFailures\": true\n          }\n        ]\n      }\n    }\n  }\n}\n" > .vimspector.json
