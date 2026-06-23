@echo off
REM HomeProtector 실행 — Windows cmd/더블클릭용 래퍼. 실제 로직은 run.ps1.
REM   run.bat            웹(Chrome), 포트 56940
REM   run.bat release    웹 릴리스 모드
REM   run.bat device     연결된 기기/에뮬레이터
REM PowerShell 실행정책을 우회해 run.ps1 을 실행한다(시스템 정책 변경 없음).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" %*
