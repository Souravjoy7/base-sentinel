# Contributing to Base Sentinel

We welcome contributions! This document provides guidelines for contributing to the Base Sentinel project.

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Contribute

### 1. Fork and Clone

```bash
git clone https://github.com/your-username/base-sentinel.git
cd base-sentinel
```

### 2. Setup Development Environment

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
npm install
```

### 3. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

### 4. Make Your Changes

- Follow the existing code style
- Add tests for new functionality
- Update documentation as needed

### 5. Test Your Changes

```bash
# Run tests
forge test

# Run with gas report
forge test --gas-report

# Run coverage
forge coverage
```

### 6. Submit a Pull Request

- Update the README.md if needed
- Ensure all tests pass
- Add a clear description of your changes

## Development Guidelines

### Smart Contract Development

- Use Solidity ^0.8.20
- Follow OpenZeppelin patterns when appropriate
- Implement proper error handling
- Add comprehensive tests
- Include comments for complex logic

### Documentation

- Update README.md for new features
- Add inline comments for complex code
- Update threat models when adding new security features

### Security Considerations

- All security reports should be submitted through the [security template](.github/ISSUE_TEMPLATE/security.md)
- Do not merge pull requests that introduce security vulnerabilities
- Review all changes for potential security implications

### Testing

- Aim for high test coverage
- Include both happy path and edge case tests
- Use Foundry testing framework
- Add gas optimization tests where relevant

## Project Structure

```
base-sentinel/
├── src/                    # Smart contracts
│   ├── SequencerWatchdog.sol
│   └── BridgeValidator.sol
├── tests/                  # Test files
│   ├── SequencerWatchdog.t.sol
│   └── BridgeValidator.t.sol
├── docs/                   # Documentation
│   └── threat-model-base.md
├── scripts/                # Helper scripts
├── .github/               # GitHub templates
└── README.md
```

## Review Process

1. All pull requests require review from at least one maintainer
2. Security-related changes require additional review
3. Automated tests must pass before review
4. Code follows project style guidelines

## Questions?

If you have questions about contributing, please open an issue or reach out to the maintainers.