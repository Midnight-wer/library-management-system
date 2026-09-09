@REM ----------------------------------------------------------------------------
@REM Licensed to the Apache Software Foundation (ASF) under one
@REM or more contributor license agreements.  See the NOTICE file
@REM distributed with this work for additional information
@REM regarding copyright ownership.  The ASF licenses this file
@REM to you under the Apache License, Version 2.0 (the
@REM "License"); you may not use this file except in compliance
@REM with the License.  You may obtain a copy of the License at
@REM
@REM    http://www.apache.org/licenses/LICENSE-2.0
@REM
@REM Unless required by applicable law or agreed to in writing,
@REM software distributed under the License is distributed on an
@REM "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
@REM KIND, either express or implied.  See the License for the
@REM specific language governing permissions and limitations
@REM under the License.
@REM ----------------------------------------------------------------------------

@REM ----------------------------------------------------------------------------
@REM Maven Start Up Batch script
@REM
@REM Required ENV vars:
@REM JAVA_HOME - location of a JDK home dir
@REM
@REM Optional ENV vars
@REM M2_HOME - location of maven2's installed home dir
@REM MAVEN_BATCH_ECHO - set to 'on' to enable the echoing of the batch commands
@REM MAVEN_BATCH_PAUSE - set to 'on' to wait for a keystroke before ending
@REM MAVEN_OPTS - parameters passed to the Java VM, e.g. -Ddebug=...
@REM ----------------------------------------------------------------------------

@REM Begin all REM lines with '@' in case MAVEN_BATCH_ECHO is 'on'
@echo off
@REM set title of command window
title %0
@REM enable echoing by setting MAVEN_BATCH_ECHO to 'on'
@if "%MAVEN_BATCH_ECHO%" == "on"  echo %0

@REM set %JAVA_HOME%
@if "%JAVA_HOME%" == "" goto JavaHomeMissing

@setlocal
set wdir=%cd%
@cd /d "%~dp0"
@set base_dir=%cd%
@cd /d "%wdir%"

@if not exist "%base_dir%\.mvn\jvm.config" goto endReadJvmConfig
@set /p MAVEN_OPTS_JVM=<"%base_dir%\.mvn\jvm.config"
@set MAVEN_OPTS=%MAVEN_OPTS% %MAVEN_OPTS_JVM%
:endReadJvmConfig

@echo Using MAVEN_OPTS: %MAVEN_OPTS%

@REM Find Java
@set MAVEN_JAVA_EXE="%JAVA_HOME%\bin\java.exe"

@REM Check Java version
@%MAVEN_JAVA_EXE% -version >nul 2>&1
if %ERRORLEVEL% neq 0 goto JavaHomeMissing

@REM Check Maven wrapper jar
@set MAVEN_WRAPPER_JAR="%base_dir%\.mvn\wrapper\maven-wrapper.jar"
@set MAVEN_WRAPPER_PROPERTIES="%base_dir%\.mvn\wrapper\maven-wrapper.properties"

@REM Provide a "standardized" way to retrieve Maven
if exist %MAVEN_WRAPPER_JAR% goto runMaven
echo Couldn't find %MAVEN_WRAPPER_JAR%, downloading from the internet...
mkdir "%base_dir%\.mvn\wrapper" 2>nul
powershell -Command "& { Invoke-WebRequest -Uri 'https://repo1.maven.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.1.1/maven-wrapper-3.1.1.jar' -OutFile '%MAVEN_WRAPPER_JAR%' }"
if not exist %MAVEN_WRAPPER_JAR% (
    echo ERROR: Failed to download Maven wrapper jar
    exit /b 1
)
:runMaven

%MAVEN_JAVA_EXE% ^
  -Dmaven.multiModuleProjectDirectory="%base_dir%" ^
  -Dmaven.home="%base_dir%\.mvn\wrapper\maven-home" ^
  -Dclassworlds.conf="%base_dir%\.mvn\wrapper\maven-wrapper.conf" ^
  -classpath %MAVEN_WRAPPER_JAR% ^
  org.apache.maven.wrapper.MavenWrapperMain %*

@echo off
goto end

:JavaHomeMissing
echo ERROR: JAVA_HOME not set in the environment.
exit /b 1

:end
@endlocal
