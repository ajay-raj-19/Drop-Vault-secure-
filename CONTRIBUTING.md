# Contributing to Drop Vault

Thank you for your interest in contributing to Drop Vault! To maintain codebase quality, security, and stability, please review the following guidelines.

---

## 1. Code of Conduct
We expect contributors to maintain a respectful, constructive, and welcoming environment for everyone in the community.

---

## 2. Development Workflow

### Step 1: Fork and Clone
Fork the repository on GitHub and clone your fork locally:
```bash
git clone https://github.com/your-username/drop_vault.git
cd drop_vault
```

### Step 2: Create a Feature Branch
Create a branch specifically for the feature or fix you are addressing:
```bash
git checkout -b feature/my-amazing-feature
```

### Step 3: Implement Changes
Adhere to the following conventions:
- Use clean, semantic Dart layout conventions.
- Place providers in their respective directories (`lib/core/providers/` or `lib/features/<name>/presentation/providers/`).
- **Aesthetic Excellence**: All UI elements should respect the premium glassmorphic styling tokens defined in `lib/core/constants/design_tokens.dart`.

---

## 3. Formatting & Linting

Before committing any modifications, run the code formatter and static analyzer:
```bash
flutter format .
flutter analyze
```
*Note: Your pull request will fail automated checks if there are any warnings, errors, or linter complaints.*

---

## 4. Submitting a Pull Request (PR)

1. Push your changes to your feature branch.
2. Open a Pull Request targeting the `main` branch.
3. Complete the PR template, describing:
   - What has been added or fixed.
   - Any dependencies added.
   - Screen captures demonstrating layout modifications.
4. Wait for a maintainer to review and approve your submission.
