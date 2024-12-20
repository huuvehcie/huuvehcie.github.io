# Сравнительная таблица Docker, Containerd, Podman и Kubernetes

 | Характеристика | Docker | Containerd | Podman | Kubernetes |
 |---------------------------------|-----------------------------------------------------------------------|----------------------------------------------------------------------|-----------------------------------------------------------------------|-----------------------------------------------------------------------|
 | Основное назначение | Контейнеризация приложений | Легковесный контейнерный рантайм | Бездемонный контейнерный рантайм | Оркестрация контейнеров |
 | Разработчик | Docker Inc. | Cloud Native Computing Foundation (CNCF) | Red Hat | Cloud Native Computing Foundation (CNCF) |
 | Лицензия | Apache License 2.0 | Apache License 2.0 | Apache License 2.0 | Apache License 2.0 |
 | Архитектура | Клиент-серверная | Модульная | Бездемонная | Клиент-серверная |
 | Поддержка OCI | Да | Да | Да | Да |
 | Поддержка Kubernetes | Да | Да | Да | - |
 | Поддержка rootless | Нет | Да | Да | Нет |
 | Поддержка CRI | Нет | Да | Нет | Да |
 | Поддержка Docker Compose | Да | Нет | Да | Нет |
 | Поддержка Dockerfile | Да | Нет | Да | Нет |
 | Поддержка Podman Compose | Нет | Нет | Да | Нет |
 | Поддержка Kubernetes Compose | Нет | Нет | Нет | Да |
 | Примеры использования | Контейнеризация веб-приложений, микросервисов | Использование в качестве рантайма для Kubernetes | Разработка и тестирование контейнеров без демона | Оркестрация микросервисов в облаке |
 | Основные компоненты | Docker Engine, Docker CLI, Docker Compose | containerd, runc | Podman, Buildah, Skopeo | kubelet, kube-apiserver, kube-controller-manager, kube-scheduler, etcd |
 | Управление контейнерами | Docker CLI | ctr CLI | Podman CLI | kubectl CLI |
 | Автоматизация развертывания | Docker Compose, Docker Swarm | Нет | Podman Compose | Kubernetes Deployments, StatefulSets, DaemonSets |
 | Мониторинг и логирование | Docker Stats, Docker Logs | Нет | Podman Stats, Podman Logs | Prometheus, Grafana, ELK Stack |
 | Безопасность | Docker Content Trust, Docker Secrets | Нет | Podman Rootless, Podman Secrets | Kubernetes RBAC, Network Policies, Secrets |
 | Примеры интеграции | Jenkins, GitLab CI/CD, AWS ECS, Azure AKS | Kubernetes, AWS ECS, Azure AKS | Jenkins, GitLab CI/CD, AWS ECS, Azure AKS | Jenkins, GitLab CI/CD, AWS EKS, Azure AKS, Google GKE |
 | Примеры использования в реальных сценариях | Контейнеризация веб-приложений для CI/CD | Использование в качестве рантайма для Kubernetes в облаке | Разработка и тестирование контейнеров без демона в локальной среде | Оркестрация микросервисов в облаке для обеспечения высокой доступности и масштабируемости |
 | Преимущества | Простота использования, большое сообщество, множество инструментов | Легковесность, совместимость с Kubernetes | Бездемонность, совместимость с Docker, безопасность | Высокая доступность, масштабируемость, автоматическое восстановление |
 | Недостатки | Требует демона, меньше безопасности в rootless режиме | Ограниченные возможности управления контейнерами | Ограниченные возможности оркестрации | Сложность настройки и управления 
