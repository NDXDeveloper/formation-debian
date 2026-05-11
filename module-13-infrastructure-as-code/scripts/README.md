# Scripts du Module 13 — Infrastructure as Code

Cette arborescence regroupe les **artefacts complets** (playbooks Ansible,  
modules Terraform, templates, configurations) extraits du Module 13 et  
organisés par outil et par section. Chaque fichier porte un en-tête  
normalisé identifiant sa section d'origine, et a été validé syntaxiquement  
dans un conteneur Debian 13.  

## Convention de nommage

```
<XX.Y>-<nom-court-kebab>.<ext>
```

| Préfixe | Section du module | Outil |
|---------|-------------------|-------|
| `01.2-*` | 13.1.2 — Inventaires Ansible | Ansible |
| `01.3-*` | 13.1.3 — Playbooks, Jinja2, handlers | Ansible |
| `01.4-*` | 13.1.4 — Rôles, collections, Galaxy | Ansible |
| `02.2-*` | 13.2.2 — Installation Terraform sur Debian | Terraform |
| `02.3-*` | 13.2.3 — État (state) et backends | Terraform |

Les **rôles Ansible** et les **modules Terraform** sont extraits sous forme  
de **dossiers complets** respectant la convention de structure attendue par  
chaque outil (ex. `roles/nginx/{tasks,handlers,defaults,templates,...}`).  

## Arborescence

```
scripts/
├── README.md                                  # Ce fichier
├── 02-ansible/
│   ├── ansible.cfg                            # Configuration projet (13.1.1)
│   ├── 01.4-collections-requirements.yml      # Collections nécessaires
│   ├── inventory/                             # Inventaires statiques + dynamiques
│   ├── group_vars/                            # Variables par groupe / hôte
│   ├── playbooks/                             # Playbooks et templates Jinja2
│   └── roles/
│       └── 01.4-role-nginx/                   # Rôle nginx complet
├── 03-terraform-opentofu/
│   ├── 02.2-terraform.gitignore               # .gitignore standard
│   ├── modules/
│   │   └── 02.2-debian-vm/                    # Module VM Debian unitaire
│   ├── environments/
│   │   └── 02.2-debian-cluster/               # Cluster multi-VM (for_each)
│   └── examples/                              # Snippets HCL standalone
└── 05-secrets-state/                          # Configurations de backend
    ├── 02.3-backend-s3-modern.tf              # S3 + use_lockfile (TF 1.10+)
    ├── 02.3-backend-s3-minio.tf               # S3-compatible (MinIO on-prem)
    └── 02.3-backend-consul.tf                 # Consul KV (on-premise)
```

## Index tabulé

### Section 13.1 — Ansible

| Fichier | Description | Validé par |
|---------|-------------|------------|
| `02-ansible/ansible.cfg` | Configuration de référence d'un projet Ansible | — |
| `02-ansible/01.4-collections-requirements.yml` | Collections Galaxy nécessaires | yamllint, yaml.safe_load |
| `02-ansible/inventory/01.2-hosts-static.yml` | Inventaire YAML hiérarchique | yamllint, yaml.safe_load |
| `02-ansible/inventory/01.2-aws-ec2-dynamic.yml` | Plugin amazon.aws.aws_ec2 | yamllint, yaml.safe_load |
| `02-ansible/inventory/01.2-hcloud-dynamic.yml` | Plugin hetzner.hcloud.hcloud | yamllint, yaml.safe_load |
| `02-ansible/inventory/01.2-kvm-libvirt-dynamic.yml` | Plugin community.libvirt.libvirt | yamllint, yaml.safe_load |
| `02-ansible/inventory/01.2-custom-inventory.py` | Script d'inventaire CMDB custom | python3 -c |
| `02-ansible/group_vars/01.2-all.yml` | Variables globales | yamllint, yaml.safe_load |
| `02-ansible/group_vars/01.2-webservers.yml` | Variables groupe webservers | yamllint, yaml.safe_load |
| `02-ansible/group_vars/01.2-host-web01.yml` | Variables host_vars web01 | yamllint, yaml.safe_load |
| `02-ansible/playbooks/01.3-webserver-base.yml` | Playbook minimal (1 play) | ansible-playbook --syntax-check |
| `02-ansible/playbooks/01.3-site-multiplay.yml` | Playbook multi-plays | ansible-playbook --syntax-check |
| `02-ansible/playbooks/01.3-rolling-update-loadbalancer.yml` | Mise à jour rolling avec serial | ansible-playbook --syntax-check |
| `02-ansible/playbooks/01.3-deploy-with-rollback.yml` | Block / rescue / always | ansible-playbook --syntax-check |
| `02-ansible/playbooks/templates/01.3-nginx.conf.j2` | Template nginx.conf | yamllint (skip), syntaxe Jinja2 |
| `02-ansible/playbooks/templates/01.3-vhost.conf.j2` | Template virtual host Nginx | yamllint (skip), syntaxe Jinja2 |
| `02-ansible/playbooks/templates/01.3-motd.j2` | MOTD dynamique | — |
| `02-ansible/playbooks/templates/01.3-hosts.j2` | /etc/hosts généré dynamiquement | — |
| `02-ansible/playbooks/templates/01.3-haproxy.cfg.j2` | Backend HAProxy avec exclusion | — |
| `02-ansible/roles/01.4-role-nginx/` | **Rôle nginx complet** | ansible-playbook --syntax-check |

### Section 13.2 — Terraform / OpenTofu

| Fichier | Description | Validé par |
|---------|-------------|------------|
| `03-terraform-opentofu/02.2-terraform.gitignore` | .gitignore standard projet TF | — |
| `03-terraform-opentofu/modules/02.2-debian-vm/` | **Module VM Debian unitaire** | terraform fmt -check, terraform validate |
| `03-terraform-opentofu/environments/02.2-debian-cluster/` | **Cluster multi-VM avec for_each** | terraform fmt -check, terraform validate |
| `03-terraform-opentofu/examples/02.1-libvirt-domain-snippet.tf` | Snippet HCL libvirt_domain | terraform fmt -check |
| `03-terraform-opentofu/examples/02.1-external-etcd-kubeadm.tf` | Data source HTTP ipify | terraform fmt -check |
| `05-secrets-state/02.3-backend-s3-modern.tf` | Backend S3 (TF 1.10+ use_lockfile) | terraform fmt -check |
| `05-secrets-state/02.3-backend-s3-minio.tf` | Backend S3 vers MinIO on-premise | terraform fmt -check |
| `05-secrets-state/02.3-backend-consul.tf` | Backend Consul KV | terraform fmt -check |


## Prérequis d'utilisation

- **Ansible** : `apt install ansible` (Debian Trixie : ansible 12.0.0)
- **Terraform** : dépôt HashiCorp APT (cf. Module 13.2.2)
- **OpenTofu** : binaire depuis github.com/opentofu/opentofu/releases
- **Provider libvirt** : nécessite `libvirt-dev`, `genisoimage`, `qemu-utils`
  et un environnement KVM/libvirt fonctionnel (cf. Module 9)

## Licence

CC BY 4.0 — Attribution 4.0 International
