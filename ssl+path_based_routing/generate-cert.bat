@echo off
REM =============================================================================
REM generate-cert.bat
REM =============================================================================
REM PURPOSE:
REM   Generates a self-signed TLS certificate for local HTTPS development.
REM   Creates two files: tls.crt (certificate) and tls.key (private key).
REM   Then creates the Kubernetes TLS Secret from those files.
REM
REM HOW TO RUN:
REM   Double-click generate-cert.bat in File Explorer
REM   OR run from CMD terminal: generate-cert.bat
REM
REM WHAT IT DOES:
REM   1. Generates tls.key (private key, 2048-bit RSA)
REM   2. Generates tls.crt (self-signed X.509 certificate, valid 365 days)
REM   3. Stores both in Kubernetes as a Secret named: app-tls-secret
REM
REM REQUIREMENT:
REM   OpenSSL must be installed and on your PATH.
REM   Install from: https://slproweb.com/products/Win32OpenSSL.html
REM   kubectl must be configured and connected to your Minikube cluster.
REM =============================================================================

echo.
echo ============================================
echo  Generating TLS certificate for local dev
echo ============================================
echo.

REM Check OpenSSL is available
where openssl >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: openssl not found on PATH.
    echo Install from: https://slproweb.com/products/Win32OpenSSL.html
    pause
    exit /b 1
)

REM Check kubectl is available
where kubectl >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: kubectl not found on PATH.
    echo Make sure Minikube is installed and running.
    pause
    exit /b 1
)

REM Step 1: Generate private key and self-signed certificate
echo Step 1: Generating tls.key and tls.crt ...
echo.

openssl req -x509 -nodes -days 365 -newkey rsa:2048 ^
  -keyout tls.key ^
  -out tls.crt ^
  -subj "/CN=127.0.0.1/O=LocalDev"

REM Explanation of flags:
REM   req -x509        Generate self-signed cert (not a Certificate Signing Request)
REM   -nodes           Do not encrypt the private key (no passphrase needed)
REM   -days 365        Certificate valid for 1 year
REM   -newkey rsa:2048 Generate new 2048-bit RSA key pair at the same time
REM   -keyout tls.key  Save private key to tls.key
REM   -out tls.crt     Save certificate to tls.crt
REM   -subj            Set certificate details without interactive prompts
REM   CN=127.0.0.1     Common Name matches our Minikube tunnel IP

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Certificate generation failed.
    echo Make sure OpenSSL is installed correctly.
    pause
    exit /b 1
)

echo.
echo SUCCESS: tls.crt and tls.key created.
echo.

REM Step 2: Delete old secret if it exists (ignore error if it doesn't)
echo Step 2: Cleaning up any existing TLS Secret ...
kubectl delete secret app-tls-secret --ignore-not-found=true
echo.

REM Step 3: Create Kubernetes TLS Secret from the generated files
echo Step 3: Creating Kubernetes TLS Secret ...
echo.

kubectl create secret tls app-tls-secret ^
  --cert=tls.crt ^
  --key=tls.key

REM Explanation:
REM   kubectl create secret tls   Create a Secret of type kubernetes.io/tls
REM   app-tls-secret              Secret name (must match secretName: in ingress.yaml)
REM   --cert=tls.crt              Path to the certificate file
REM   --key=tls.key               Path to the private key file

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to create Kubernetes Secret.
    echo Make sure minikube is running: minikube status
    pause
    exit /b 1
)

echo.
echo ============================================
echo  Done! Secret created successfully.
echo ============================================
echo.

REM Step 4: Verify the secret was created
echo Verifying Secret:
kubectl get secret app-tls-secret

echo.
echo Next step: kubectl apply -f ingress.yaml
echo.
pause
