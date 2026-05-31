# Contributing to TNI-Mods

Thank you for your interest in contributing to the Tower Networking Inc Modding Kit! This document provides guidelines and best practices for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for everyone. Please:

- Be respectful and considerate in all interactions
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

1. **Fork the repository** to your GitHub account
2. **Clone your fork** locally:
   ```sh
   git clone https://github.com/YOUR-USERNAME/TNI-Mods.git
   cd TNI-Mods
   git submodule update --init --recursive
   ```
3. **Set up your development environment** following the [build instructions](README.md#building-cc-mods)
4. **Create a branch** for your work:
   ```sh
   git checkout -b feature/your-feature-name
   ```

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

- **Bug fixes**: Fix issues in existing mods or documentation
- **New example mods**: Create new examples demonstrating different modding techniques
- **Documentation improvements**: Clarify existing docs or add new guides
- **Build system improvements**: Enhance the build process or tooling
- **API enhancements**: Propose improvements to the modding API (discuss first!)

### Before You Start

- **Check existing issues** to avoid duplicating work
- **Open an issue** for significant changes to discuss your approach
- **Ask questions** if anything is unclear - we're here to help!

## Development Workflow

### For Code Changes

1. **Write clear, focused code**: Make minimal, surgical changes
2. **Follow existing patterns**: Match the style of surrounding code
3. **Test thoroughly**: Build and test your changes
4. **Document your changes**: Update relevant documentation

### For Documentation Changes

1. **Keep it clear and concise**: Use simple language
2. **Provide examples**: Show, don't just tell
3. **Test all commands**: Ensure code snippets work
4. **Check formatting**: Preview markdown rendering

## Coding Standards

### C/C++ Code

- **Use modern C++17 features** where appropriate
- **Follow existing naming conventions**:
  - Functions: `snake_case`
  - Variables: `snake_case`
  - Classes: `PascalCase`
  - Constants: `UPPER_SNAKE_CASE`
- **Add comments** for complex logic or non-obvious code
- **Use descriptive variable names**: Prefer `bandwidth` over `bw`
- **Handle errors gracefully**: Check return values and optional types

### Lua Code

- **Follow Lua community conventions**:
  - Variables and functions: `snake_case`
  - Constants: `UPPER_SNAKE_CASE` (if used)
- **Add type annotations** where available (`---@param`, `---@type`)
- **Use descriptive names**: Avoid cryptic abbreviations
- **Comment complex logic**: Help others understand your intent
- **Check for nil values**: Handle edge cases

### Documentation

- **Use proper markdown formatting**
- **Include code blocks** with appropriate syntax highlighting
- **Keep line length reasonable**: ~80-100 characters when practical
- **Use clear headings**: Make documentation scannable
- **Update table of contents** when adding new sections

## Submitting Changes

### Before Submitting

- [ ] Code builds successfully on the target platform(s)
- [ ] Changes have been tested
- [ ] Documentation is updated (if applicable)
- [ ] Commit messages are clear and descriptive
- [ ] No unnecessary files are included (build artifacts, etc.)

### Pull Request Process

1. **Update your branch** with the latest main:
   ```sh
   git fetch origin
   git rebase origin/main
   ```

2. **Push your changes**:
   ```sh
   git push origin feature/your-feature-name
   ```

3. **Open a Pull Request** on GitHub:
   - Use a clear, descriptive title
   - Reference any related issues (e.g., "Fixes #123")
   - Describe what changes you made and why
   - Include screenshots for UI changes
   - List any breaking changes

4. **Respond to feedback**:
   - Be open to suggestions and changes
   - Update your PR based on review comments
   - Push additional commits to the same branch

### Commit Messages

Write clear, meaningful commit messages:

```
Short summary (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain what changed and why, not how (the code shows how).

- Use bullet points for multiple changes
- Reference issues: Fixes #123, Closes #456
```

**Good examples**:
- ✅ `Add example mod demonstrating UI creation`
- ✅ `Fix bandwidth calculation in switch spawner`
- ✅ `Update README with clearer build instructions`

**Bad examples**:
- ❌ `Fixed stuff`
- ❌ `Update`
- ❌ `asdf`

## Reporting Issues

### Bug Reports

When reporting a bug, include:

- **Clear description** of the problem
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Environment details**:
  - Operating system and version
  - Compiler/toolchain version
  - Game version
- **Relevant logs** or error messages
- **Code samples** if applicable (keep them minimal)

### Feature Requests

When suggesting a feature:

- **Explain the use case**: What problem does it solve?
- **Describe the desired behavior**: What should happen?
- **Consider alternatives**: Are there other ways to achieve this?
- **Discuss implementation**: Any ideas on how to build it?

## Questions?

- **Open an issue** with the "question" label
- **Check existing documentation** and issues first
- **Be specific** about what you need help with

## License

By contributing, you agree that your contributions will be licensed under the same [BSD 3-Clause License](LICENSE) as the project.

---

Thank you for contributing to TNI-Mods! Your efforts help make modding Tower Networking Inc better for everyone. 🎉
