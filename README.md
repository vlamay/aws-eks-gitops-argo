# GitOps Platform - Production-Ready MLOps/DevOps Solution

[![Infrastructure](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)](https://terraform.io)
[![Kubernetes](https://img.shields.io/badge/K8s-EKS-326CE5?logo=kubernetes)](https://kubernetes.io)
[![GitOps](https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?logo=argo)](https://argoproj.github.io)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazon-aws)](https://aws.amazon.com)

## 🎯 Project Overview

Enterprise-grade GitOps platform built on AWS EKS with complete MLOps/DevOps capabilities. This project demonstrates production-ready infrastructure-as-code practices, GitOps workflows, and comprehensive observability.

### Key Features

- **🏗️ Infrastructure as Code**: Complete AWS infrastructure managed by Terraform
- **🔄 GitOps Workflow**: Argo CD for declarative continuous delivery
- **📊 Full Observability**: Prometheus, Grafana, Loki integration
- **🤖 MLOps Ready**: Kubeflow, MLflow, Seldon Core for ML workflows
- **🔒 Security First**: IRSA, OPA policies, Sealed Secrets, Falco runtime security
- **📈 Auto-scaling**: Cluster Autoscaler, HPA, VPA configurations
- **🚀 Progressive Delivery**: Argo Rollouts with canary/blue-green strategies

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                  │  │
│  │  ┌──────────────┐         ┌──────────────┐           │  │
│  │  │  Public AZ-A │         │  Public AZ-B │           │  │
│  │  │  10.0.1.0/24 │         │  10.0.2.0/24 │           │  │
│  │  │              │         │              │           │  │
│  │  │  NAT Gateway │         │  NAT Gateway │           │  │
│  │  └──────┬───────┘         └──────┬───────┘           │  │
│  │         │                        │                   │  │
│  │  ┌──────▼───────┐         ┌──────▼───────┐           │  │
│  │  │ Private AZ-A │         │ Private AZ-B │           │  │
│  │  │ 10.0.11.0/24 │         │ 10.0.12.0/24 │           │  │
│  │  │              │         │              │           │  │
│  │  │ ┌──────────┐ │         │ ┌──────────┐ │           │  │
│  │  │ │EKS Nodes │ │         │ │EKS Nodes │ │           │  │
│  │  │ └──────────┘ │         │ └──────────┘ │           │  │
│  │  └──────────────┘         └──────────────┘           │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    EKS Cluster Components                    │
├─────────────────────────────────────────────────────────────┤
│ GitOps Layer      │ Argo CD, Workflows, Rollouts           │
│ Observability     │ Prometheus, Grafana, Loki, Tempo       │
│ Security          │ OPA, Falco, Sealed Secrets             │
│ MLOps             │ Kubeflow, MLflow, Seldon Core          │
│ Networking        │ AWS LB Controller, Ingress NGINX       │
│ Storage           │ EBS CSI Driver, EFS CSI Driver         │
└─────────────────────────────────────────────────────────────┘
```

## 🗂️ Project Structure

```
gitops-platform/
├── terraform/                      # Infrastructure as Code
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── modules/
│   │   ├── vpc/
│   │   ├── eks/
│   │   ├── irsa/
│   │   └── security/
│   └── backend.tf
│
├── kubernetes/                     # Kubernetes manifests
│   ├── argocd/                    # Argo CD bootstrap
│   ├── core/                      # Core platform services
│   ├── observability/             # Monitoring stack
│   ├── security/                  # Security components
│   ├── mlops/                     # MLOps platform
│   └── applications/              # Sample applications
│
├── argocd-apps/                   # Argo CD Application definitions
│   ├── app-of-apps.yaml
│   ├── core-apps.yaml
│   ├── observability-apps.yaml
│   └── mlops-apps.yaml
│
├── scripts/                       # Automation scripts
│   ├── bootstrap.sh
│   ├── install-argocd.sh
│   └── setup-kubeconfig.sh
│
├── docs/                          # Documentation
│   ├── architecture.md
│   ├── deployment-guide.md
│   ├── mlops-guide.md
│   └── troubleshooting.md
│
└── .gitlab-ci.yml                # CI/CD pipeline
```

## 🚀 Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform >= 1.6.0
- kubectl >= 1.28
- helm >= 3.12
- argocd CLI (optional)

### Step 1: Deploy Infrastructure

```bash
# Clone repository
git clone <your-repo-url>
cd gitops-platform

# Initialize Terraform
cd terraform/environments/dev
terraform init

# Review plan
terraform plan

# Deploy infrastructure
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name gitops-dev-cluster
```

### Step 2: Bootstrap GitOps

```bash
# Install Argo CD
./scripts/install-argocd.sh

# Get Argo CD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login: https://localhost:8080
# Username: admin
# Password: <from above command>
```

### Step 3: Deploy Platform Applications

```bash
# Apply App of Apps pattern
kubectl apply -f argocd-apps/app-of-apps.yaml

# Monitor deployment
argocd app list
argocd app sync <app-name>
```

## 📊 Access Platform Services

After deployment, services are available at:

- **Argo CD**: `https://argocd.yourdomain.com`
- **Grafana**: `https://grafana.yourdomain.com`
- **Prometheus**: `https://prometheus.yourdomain.com`
- **MLflow**: `https://mlflow.yourdomain.com`
- **Kubeflow**: `https://kubeflow.yourdomain.com`

## 🔐 Security Features

- **IRSA**: Fine-grained IAM permissions for pods
- **Sealed Secrets**: Encrypted secrets in Git
- **OPA Gatekeeper**: Policy enforcement
- **Falco**: Runtime security monitoring
- **Network Policies**: Pod-to-pod communication control
- **AWS Security Groups**: Network isolation

## 📈 Monitoring & Observability

- **Metrics**: Prometheus + Grafana dashboards
- **Logs**: Loki with Grafana integration
- **Traces**: Tempo for distributed tracing
- **Alerts**: AlertManager with Slack/PagerDuty integration

## 🤖 MLOps Capabilities

- **Experiment Tracking**: MLflow
- **Pipeline Orchestration**: Kubeflow Pipelines
- **Model Serving**: Seldon Core with A/B testing
- **Feature Store**: Integration ready
- **Model Monitoring**: Custom Prometheus metrics

## 🔄 GitOps Workflow

```
Developer → Git Push → GitLab CI → Container Registry
                              ↓
                         Update Manifests
                              ↓
                         Argo CD Detects
                              ↓
                      Sync to Kubernetes
                              ↓
                    Argo Rollouts (Canary)
                              ↓
                      Production Traffic
```

## 📚 Documentation

- [Architecture Deep Dive](docs/architecture.md)
- [Deployment Guide](docs/deployment-guide.md)
- [MLOps Workflows](docs/mlops-guide.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🧪 Testing

```bash
# Validate Terraform
terraform validate

# Lint Kubernetes manifests
kubectl apply --dry-run=client -f kubernetes/

# Test Argo CD sync
argocd app sync --dry-run <app-name>
```

## 🛠️ Troubleshooting

### Common Issues

**EKS Cluster Access**
```bash
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>
```

**Argo CD Sync Issues**
```bash
argocd app get <app-name>
argocd app logs <app-name>
```

**Pod Not Starting**
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

## 📈 Roadmap

- [ ] Multi-cluster support with Argo CD
- [ ] Service mesh integration (Istio)
- [ ] Advanced ML pipeline templates
- [ ] Disaster recovery automation
- [ ] Cost optimization with Karpenter
- [ ] Multi-tenancy with virtual clusters

## 🤝 Contributing

This is a portfolio project, but suggestions are welcome!

## 📄 License

MIT License - feel free to use for learning and portfolio purposes

## 👤 Author

**Vladyslav Maidaniuk**
- GitHub: [@vlamay](https://github.com/vlamay)
- LinkedIn: [Vladyslav Maidaniuk](https://linkedin.com/in/maidaniuk)
- Email: vla.maidaniuk@gmail.com

---

**Built with ❤️ for Platform Engineering & MLOps**
