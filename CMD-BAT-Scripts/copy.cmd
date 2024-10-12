@echo off
cd /d "C:\Users\user"
for /f "usebackq delims=" %%a in ("wlb*") do (
    for /f "delims=" %%b in ('dir "%%a" /b /s /a-d ') do copy "%%b" "C:\Backup"
)