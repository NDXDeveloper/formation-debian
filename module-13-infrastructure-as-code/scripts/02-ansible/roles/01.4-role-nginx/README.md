# Rôle Ansible : nginx (Section 13.1.4)

Installation et configuration de Nginx sur Debian, structuré selon les  
conventions de rôles Ansible Galaxy.  

## Structure

```
01.4-role-nginx/
├── defaults/main.yml      # Variables surchargeables
├── vars/
│   ├── main.yml           # Variables internes
│   └── Debian.yml         # Variables famille Debian (chargées dynamiquement)
├── tasks/
│   ├── main.yml           # Orchestrateur
│   ├── install.yml        # Installation
│   ├── configure.yml      # Configuration principale
│   └── vhosts.yml         # Virtual hosts
├── handlers/main.yml      # Handlers (reload, restart, validate)
├── templates/             # Templates Jinja2 (nginx.conf, vhost.conf)
├── meta/main.yml          # Métadonnées + dépendances
└── README.md              # Ce fichier
```

## Utilisation

```yaml
- hosts: webservers
  become: true
  roles:
    - role: nginx
      vars:
        nginx_worker_processes: 4
        nginx_vhosts:
          - server_name: www.example.com
            document_root: /var/www/example
            ssl: true
```

## Variables principales

| Variable | Défaut | Description |
|----------|--------|-------------|
| `nginx_package_name` | `nginx` | Paquet APT à installer |
| `nginx_worker_processes` | `auto` | Nombre de workers Nginx |
| `nginx_worker_connections` | `1024` | Connexions par worker |
| `nginx_keepalive_timeout` | `65` | Timeout keepalive (s) |
| `nginx_enable_gzip` | `true` | Activer gzip |
| `nginx_remove_default_vhost` | `true` | Supprimer le vhost par défaut |
| `nginx_vhosts` | `[]` | Liste des virtual hosts |

## Dépendances

- `common` : configuration de base du système
- `firewall` : règles UFW (ports 80/443 ouverts automatiquement)

## Compatibilité

- Debian 12 (Bookworm)
- Debian 13 (Trixie)
- ansible-core ≥ 2.18

## Licence

CC BY 4.0
