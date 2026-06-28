# Admin Account Setup Script
# Run this after deploying the updated GraphQL schema

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LifePulse Admin Account Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Push updated GraphQL schema
Write-Host "[1/3] Pushing updated GraphQL schema to AWS..." -ForegroundColor Yellow
Write-Host "This will add 'imageUrl' and 'is24Hours' fields to Hospital model" -ForegroundColor Gray
Write-Host ""
Write-Host "Run this command:" -ForegroundColor Green
Write-Host "  amplify push" -ForegroundColor White
Write-Host ""
Write-Host "When prompted:" -ForegroundColor Gray
Write-Host "  - Do you want to generate code? → Yes" -ForegroundColor Gray
Write-Host "  - Choose the code generation language target → dart" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter after you've run 'amplify push' successfully"

Write-Host ""
Write-Host "[2/3] Creating Admin User Account..." -ForegroundColor Yellow
Write-Host ""

# Get admin details from user
$adminEmail = Read-Host "Enter admin email address"
$adminPassword = Read-Host "Enter admin password (min 8 characters)" -AsSecureString
$adminName = Read-Host "Enter admin name"

# Convert secure string to plain text for AWS CLI
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host ""
Write-Host "Creating user in Cognito..." -ForegroundColor Gray

# Get User Pool ID from Amplify
$amplifyMeta = Get-Content "amplify\#current-cloud-backend\amplify-meta.json" | ConvertFrom-Json
$userPoolId = $amplifyMeta.auth.PSObject.Properties.Value.output.UserPoolId
$region = "ap-southeast-2"  # Your AWS region

if (-not $userPoolId) {
    Write-Host "Error: Could not find User Pool ID in amplify-meta.json" -ForegroundColor Red
    exit 1
}

Write-Host "User Pool ID: $userPoolId" -ForegroundColor Gray
Write-Host ""

# Create user via AWS CLI
Write-Host "Creating user account..." -ForegroundColor Gray
$createUserResult = aws cognito-idp admin-create-user `
    --user-pool-id $userPoolId `
    --username $adminEmail `
    --user-attributes Name=email,Value=$adminEmail Name=email_verified,Value=true Name=name,Value=$adminName Name=custom:role,Value=admin `
    --temporary-password $plainPassword `
    --message-action SUPPRESS `
    --region $region 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error creating user: $createUserResult" -ForegroundColor Red
    exit 1
}

Write-Host "✓ User created successfully!" -ForegroundColor Green
Write-Host ""

# Set permanent password
Write-Host "Setting permanent password..." -ForegroundColor Gray
$setPasswordResult = aws cognito-idp admin-set-user-password `
    --user-pool-id $userPoolId `
    --username $adminEmail `
    --password $plainPassword `
    --permanent `
    --region $region 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error setting password: $setPasswordResult" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Password set successfully!" -ForegroundColor Green
Write-Host ""

# Add user to Admins group
Write-Host "[3/3] Adding user to Admins group..." -ForegroundColor Yellow
$addToGroupResult = aws cognito-idp admin-add-user-to-group `
    --user-pool-id $userPoolId `
    --username $adminEmail `
    --group-name "Admins" `
    --region $region 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error adding to group: $addToGroupResult" -ForegroundColor Red
    exit 1
}

Write-Host "✓ User added to Admins group!" -ForegroundColor Green
Write-Host ""

# Create AdminUser record in database
Write-Host "Creating AdminUser record in database..." -ForegroundColor Gray
Write-Host ""
Write-Host "You need to create an AdminUser record manually via AWS AppSync console or use this mutation:" -ForegroundColor Yellow
Write-Host ""
Write-Host "mutation CreateAdminUser {" -ForegroundColor White
Write-Host "  createAdminUser(input: {" -ForegroundColor White
Write-Host "    userId: `"$adminEmail`"" -ForegroundColor White
Write-Host "    name: `"$adminName`"" -ForegroundColor White
Write-Host "    email: `"$adminEmail`"" -ForegroundColor White
Write-Host "  }) {" -ForegroundColor White
Write-Host "    id" -ForegroundColor White
Write-Host "    userId" -ForegroundColor White
Write-Host "    name" -ForegroundColor White
Write-Host "    email" -ForegroundColor White
Write-Host "  }" -ForegroundColor White
Write-Host "}" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✓ Admin Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Admin Credentials:" -ForegroundColor Yellow
Write-Host "  Email: $adminEmail" -ForegroundColor White
Write-Host "  Password: [the password you entered]" -ForegroundColor White
Write-Host "  Role: admin" -ForegroundColor White
Write-Host "  Group: Admins" -ForegroundColor White
Write-Host ""
Write-Host "You can now login to the admin panel using these credentials!" -ForegroundColor Green
Write-Host ""
