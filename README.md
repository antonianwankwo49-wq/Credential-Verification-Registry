# 🎓 Credential Verification Registry

A tamper-proof blockchain-based credential verification system that issues diplomas as NFTs, verifiable against Bitcoin timestamps. This system streamlines job hiring by eliminating fake degrees in creative fields and beyond.

## 🚀 Features

- **🔐 Tamper-Proof Credentials**: Issue diplomas as NFTs that cannot be forged or altered
- **⏰ Bitcoin Timestamping**: Each credential is timestamped against the Bitcoin blockchain for ultimate verification
- **🏛️ Institution Registry**: Only authorized institutions can issue credentials
- **✅ Real-time Verification**: Instantly verify the authenticity and validity of any credential
- **📊 Analytics Dashboard**: Track credential issuance and revocation statistics
- **🔄 Transferable Credentials**: Recipients can transfer their credentials to new addresses
- **⚡ Emergency Controls**: Contract owner can pause operations if needed

## 📋 Contract Overview

The Credential Verification Registry consists of several core components:

### 🏢 Institution Management
- Register authorized educational institutions
- Track institution statistics and activity
- Deauthorize institutions when necessary

### 🎓 Credential Issuance
- Mint credential NFTs to recipients
- Store comprehensive credential metadata
- Link credentials to Bitcoin block timestamps
- Support optional expiration dates and grades

### 🔍 Verification System
- Verify credential authenticity in real-time
- Check revocation status
- Validate expiration dates
- Count valid credentials per recipient

### 🔧 Administrative Functions
- Emergency pause/resume capabilities
- Credential revocation by issuing institutions
- Credential transfer between addresses

## 🛠️ Usage Instructions

### For Contract Owners

#### Register an Institution
```clarity
(contract-call? .credential-verification-registry register-institution 
  "University Name" 
  "Country" 
  "Accreditation Level")
```

#### Emergency Controls
```clarity
;; Pause contract operations
(contract-call? .credential-verification-registry emergency-pause)

;; Resume contract operations
(contract-call? .credential-verification-registry resume-contract)

;; Deauthorize an institution
(contract-call? .credential-verification-registry deauthorize-institution 'SP123...)
```

### For Educational Institutions

#### Issue a Credential
```clarity
(contract-call? .credential-verification-registry issue-credential
  'SP123RECIPIENT... ;; recipient address
  "Bachelor of Science" ;; credential type
  "Computer Science" ;; field of study
  (some u10000) ;; expiry in blocks (optional)
  "ipfs://metadata-uri" ;; metadata URI
  (some "A+") ;; grade (optional)
)
```

#### Revoke a Credential
```clarity
(contract-call? .credential-verification-registry revoke-credential u1)
```

### For Recipients

#### Transfer a Credential
```clarity
(contract-call? .credential-verification-registry transfer-credential 
  u1 ;; credential ID
  'SP456NEWOWNER... ;; new recipient address
)
```

### For Verifiers (Employers, etc.)

#### Verify a Credential
```clarity
(contract-call? .credential-verification-registry verify-credential u1)
```

#### Get Credential Details
```clarity
(contract-call? .credential-verification-registry get-credential u1)
```

#### Count Valid Credentials
```clarity
(contract-call? .credential-verification-registry count-valid-credentials 'SP123...)
```

## 📊 Read-Only Functions

### Contract Information
- `get-contract-info`: Get contract owner, status, and next credential ID
- `get-credential`: Retrieve full credential details
- `get-institution`: Get institution information
- `get-recipient-credentials`: List all credentials for a recipient
- `get-institution-stats`: View institution statistics

### Verification Functions
- `verify-credential`: Complete credential verification with validity status
- `is-institution-authorized`: Check if an institution is authorized
- `get-credential-owner`: Get the current owner of a credential NFT
- `count-valid-credentials`: Count valid credentials for a recipient

## 🔧 Development Setup

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet/) installed
- Node.js and npm for testing

### Installation
```bash
# Clone the repository
git clone https://github.com/your-username/credential-verification-registry
cd credential-verification-registry

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test
```

## 🧪 Testing

Run the comprehensive test suite:
```bash
npm test
```

Tests cover:
- ✅ Institution registration and management
- ✅ Credential issuance and validation
- ✅ Verification workflows
- ✅ Transfer functionality
- ✅ Revocation processes
- ✅ Error handling and edge cases

## 🔐 Security Features

- **Access Control**: Only authorized institutions can issue credentials
- **Immutable Records**: Blockchain-based storage prevents tampering
- **Bitcoin Timestamping**: Additional security layer with Bitcoin block references
- **Emergency Controls**: Contract owner can pause operations if needed
- **Revocation System**: Institutions can revoke compromised credentials

## 🌟 Use Cases

### 🎨 Creative Industries
- Art school diplomas
- Design certifications
- Music conservatory degrees
- Film school credentials

### 💼 Professional Certifications
- Technical certifications
- Professional licenses
- Continuing education credits
- Industry-specific qualifications

### 🎓 Academic Credentials
- University degrees
- Online course completions
- Professional development certificates
- Skill-based certifications

## 🚀 Deployment

Deploy to Stacks blockchain:
```bash
# Deploy to testnet
clarinet deployments apply --devnet

# Deploy to mainnet (when ready)
clarinet deployments apply --mainnet
```

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/)

---

**Built with ❤️ on the Stacks blockchain** 🚀

# Credential Verification Registry

