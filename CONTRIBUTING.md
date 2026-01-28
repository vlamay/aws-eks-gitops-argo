# Contributing to GitOps Platform

Thank you for your interest in improving this GitOps platform project!

## Project Status

This is currently a **portfolio/learning project** in active development. While it's primarily for demonstration purposes, contributions and suggestions are welcome.

## How to Contribute

### Reporting Issues

If you find bugs or have suggestions:
1. Check existing issues first
2. Create a new issue with:
   - Clear description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment details

### Suggesting Enhancements

For new features or improvements:
1. Open an issue describing:
   - The enhancement
   - Use case/benefit
   - Proposed implementation (optional)

### Code Contributions

#### Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/gitops-platform.git
   cd gitops-platform
   ```

3. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### Development Guidelines

**Terraform Code**:
- Follow HashiCorp style guide
- Use meaningful variable names
- Add descriptions to all variables
- Include examples in comments
- Run `terraform fmt` before committing
- Validate with `terraform validate`

**Kubernetes Manifests**:
- Use YAML format
- Follow Kubernetes best practices
- Include resource limits
- Add labels and annotations
- Validate with `kubectl apply --dry-run=client`

**Documentation**:
- Use clear, concise language
- Include code examples
- Add diagrams where helpful
- Keep README up to date

**Scripts**:
- Add error handling
- Include usage examples
- Make scripts idempotent
- Add comments for complex logic

#### Commit Messages

Follow conventional commits format:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

**Examples**:
```
feat(eks): add GPU node group support

Add configuration for GPU-enabled node groups to support
ML workloads requiring CUDA.

Closes #123
```

```
docs(readme): update quick start guide

Clarify prerequisites and add troubleshooting section.
```

#### Pull Request Process

1. Update documentation for any changes
2. Test your changes thoroughly
3. Run validation:
   ```bash
   # Terraform
   terraform fmt -recursive
   terraform validate
   
   # Kubernetes
   kubectl apply --dry-run=client -f kubernetes/
   ```

4. Create pull request with:
   - Clear title and description
   - Reference to related issues
   - Screenshots (if UI changes)
   - Testing performed

5. Wait for review and address feedback

## Development Setup

### Prerequisites

- AWS CLI v2
- Terraform >= 1.6.0
- kubectl >= 1.28
- helm >= 3.12
- Git

### Local Development

1. **Set up AWS credentials**:
   ```bash
   aws configure
   ```

2. **Initialize Terraform**:
   ```bash
   cd terraform/environments/dev
   terraform init
   ```

3. **Plan changes**:
   ```bash
   terraform plan
   ```

4. **Test without applying**:
   ```bash
   terraform plan -out=tfplan
   # Review the plan
   rm tfplan  # Don't apply in development
   ```

### Testing

**Terraform**:
```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform validate

# Security scan
tfsec terraform/
```

**Kubernetes**:
```bash
# Dry run
kubectl apply --dry-run=client -f kubernetes/

# YAML lint
yamllint kubernetes/
```

## Project Structure

```
gitops-platform/
├── terraform/          # Infrastructure as Code
│   ├── modules/       # Reusable Terraform modules
│   └── environments/  # Environment-specific configs
├── kubernetes/        # Kubernetes manifests
├── argocd-apps/      # Argo CD applications
├── scripts/          # Automation scripts
└── docs/             # Documentation
```

## Areas for Contribution

### High Priority
- [ ] Complete EKS Terraform module
- [ ] Dev environment configuration
- [ ] Bootstrap automation script
- [ ] Argo CD application manifests
- [ ] Deployment documentation

### Medium Priority
- [ ] Observability stack configuration
- [ ] MLOps components
- [ ] CI/CD pipeline
- [ ] Security hardening
- [ ] Cost optimization

### Low Priority
- [ ] Multi-environment support (staging, prod)
- [ ] Service mesh integration
- [ ] Advanced monitoring dashboards
- [ ] Sample applications
- [ ] Video tutorials

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the project
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Public or private harassment
- Publishing others' private information
- Other unprofessional conduct

## Questions?

Feel free to:
- Open an issue for questions
- Reach out via email: vla.maidaniuk@gmail.com
- Connect on LinkedIn: [Vladyslav Maidaniuk](https://linkedin.com/in/maidaniuk)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to making this project better!** 🚀
