# Принципы работы облачной инфраструктуры

## Определения

| Термин | Определение |
|-|-|
| Облачная инфраструктура | Комплекс ресурсов (серверы, сети, хранилища), доступных по сети и предоставляемых как услуга. |
| Облачные сервисы | Услуги, предоставляемые через интернет, которые позволяют пользователям использовать ресурсы без необходимости их физического владения. |

## Уровни облачных сервисов

| Уровень сервиса | Описание | Примеры |
|-|-|-|
| IaaS (Infrastructure as a Service) | Предоставление виртуализированных вычислительных ресурсов через интернет. Пользователь отвечает за управление ОС и приложениями. | Amazon EC2, Google Compute Engine, Microsoft Azure VMs |
| PaaS (Platform as a Service) | Платформа для разработки, тестирования и развертывания приложений. Пользователь управляет приложениями, а провайдер — инфраструктурой. | Google App Engine, Heroku, Microsoft Azure App Services |
| SaaS (Software as a Service) | Программное обеспечение, доступное через интернет. Пользователь получает доступ к приложениям без необходимости установки и управления ими. | Google Workspace, Microsoft 365, Salesforce |
| FaaS (Function as a Service) | Модель, в которой пользователи могут запускать код в ответ на события без управления серверами. | AWS Lambda, Azure Functions, Google Cloud Functions |
| CaaS (Container as a Service) | Облачное решение для управления контейнерами, позволяющее развертывать и управлять приложениями в контейнерах. | Google Kubernetes Engine, Amazon ECS, Azure Kubernetes Service |
| DaaS (Desktop as a Service) | Облачное решение для предоставления виртуальных рабочих столов пользователям через интернет. | Amazon WorkSpaces, Citrix Virtual Apps and Desktops |
| SecaaS (Security as a Service) | Облачные решения для обеспечения безопасности, включая защиту данных, мониторинг угроз и управление доступом. | McAfee MVISION Cloud, Zscaler, Cisco Umbrella |
| BaaS (Backend as a Service) | Облачные решения, предоставляющие серверную часть для мобильных и веб-приложений. | Firebase, Backendless, Kinvey |

# Компоненты облачных сервисов по функциональности

 | Компоненты и функциональность | Описание | Microsoft Azure | Google Cloud Platform (GCP) | Amazon Web Services (AWS) | Yandex Cloud |
 |-|-|-|-|-|-|
 | **Виртуальные машины** | Основной компонент для запуска виртуальных машин | Azure Virtual Machines | Compute Engine | EC2 (Elastic Compute Cloud) | Compute Cloud |
 | **Управление** | Инструмент для управления облачными ресурсами | Azure Portal, Azure CLI | Google Cloud Console, gcloud CLI | AWS Management Console, AWS CLI | Yandex Cloud Console, yc CLI |
 | **Поддержка ОС** | Операционные системы, поддерживаемые в облаке | Windows, Linux | Windows, Linux | Windows, Linux | Windows, Linux |
 | **Максимальное количество ВМ**| Максимальное количество виртуальных машин на проект | Зависит от квоты | Зависит от квоты | Зависит от квоты | Зависит от квоты |
 | **Поддержка Live Migration** | Возможность переноса работающих виртуальных машин между хостами без простоя | Да | Да | Да | Да |
 | **Поддержка Snapshots** | Возможность создания снимков состояния виртуальных машин для быстрого восстановления | Да | Да | Да | Да |
 | **Поддержка High Availability**| Обеспечение высокой доступности виртуальных машин | Да | Да | Да | Да |
 | **Поддержка Dynamic Memory** | Возможность динамического распределения памяти между виртуальными машинами | Да | Да | Да | Да |
 | **Поддержка Storage Migration**| Возможность переноса хранилища виртуальных машин между хостами | Да | Да | Да | Да |
 | **Поддержка Clustering** | Поддержка кластеризации для повышения отказоустойчивости и производительности | Да | Да | Да | Да |
 | **Поддержка Nested Virtualization**| Возможность запуска виртуальных машин внутри других виртуальных машин | Да | Да | Да | Да |
 | **Лицензирование** | Модель лицензирования | Подписка | Подписка | Подписка | Подписка |
 | **Поддержка GPU Passthrough** | Возможность проброса графического процессора в виртуальную машину | Да | Да | Да | Да |
 | **Поддержка Network Virtualization**| Возможность виртуализации сети для изоляции и управления трафиком | Да | Да | Да | Да |
 | **Поддержка Multi-tenancy** | Поддержка многопользовательской среды для изоляции и управления ресурсами | Да | Да | Да | Да |
 | **Интеграция с облачными сервисами**| Интеграция с другими облачными платформами для гибридных решений | Да | Да | Да | Да |
 | **Поддержка API** | Наличие API для автоматизации и интеграции с другими системами | Да | Да | Да | Да |
 | **Поддержка Disaster Recovery**| Возможность восстановления после сбоев и аварий | Да | Да | Да | Да |
 | **Поддержка Backup and Restore**| Возможность резервного копирования и восстановления виртуальных машин | Да | Да | Да | Да |
 | **Поддержка Containerization**| Поддержка контейнеризации для изоляции и управления приложениями | Azure Kubernetes Service (AKS) | Google Kubernetes Engine (GKE) | Amazon Elastic Kubernetes Service (EKS) | Yandex Managed Service for Kubernetes |
 | **Поддержка Multi-hypervisor Management**| Возможность управления несколькими гипервизорами из одного интерфейса | Да | Да | Да | Да |
 | **Виртуальные коммутаторы (vSwitch)** | Виртуальные коммутаторы для управления сетевыми соединениями | Azure Virtual Network | VPC (Virtual Private Cloud) | VPC (Virtual Private Cloud) | Virtual Private Cloud |
 | **Сетевые функции** | Дополнительные сетевые функции, такие как VLAN, QoS и т.д. | VLAN, QoS | VLAN, QoS | VLAN, QoS | VLAN, QoS |
 | **Встроенные средства защиты**| Встроенные средства защиты для обеспечения безопасности виртуальных машин | Azure Security Center | Google Cloud Security Command Center | AWS Shield, AWS WAF | Yandex Cloud Security |
 
 # Компоненты облачных сервисов по уровням сервиса
 
 | Уровень сервиса | Описание | Microsoft Azure | Google Cloud Platform (GCP) | Amazon Web Services (AWS) | Yandex Cloud |
 |-|-|-|-|-|-|
 | **IaaS** | Инфраструктура как услуга | Azure Virtual Machines, Azure Storage, Azure Networking | Compute Engine, Google Cloud Storage, VPC | EC2, S3, VPC | Compute Cloud, Object Storage, VPC |
 | **PaaS** | Платформа как услуга | Azure App Service, Azure Functions, Azure SQL Database | App Engine, Cloud Functions, Cloud SQL | Elastic Beanstalk, Lambda, RDS | App Engine, Functions, Managed Service for PostgreSQL |
 | **SaaS** | Программное обеспечение как услуга | Office 365, Dynamics 365 | G Suite, Google Workspace | Amazon WorkSpaces, Amazon Chime | Yandex.Mail, Yandex.Disk |
 | **FaaS** | Функции как услуга | Azure Functions | Cloud Functions | Lambda | Functions |
 | **CaaS** | Контейнеры как услуга | Azure Kubernetes Service (AKS) | Google Kubernetes Engine (GKE) | Amazon Elastic Kubernetes Service (EKS) | Yandex Managed Service for Kubernetes |
 | **SecaaS** | Безопасность как услуга | Azure Security Center, Azure Sentinel | Google Cloud Security Command Center, Chronicle | AWS Shield, AWS WAF, AWS GuardDuty | Yandex Cloud Security, Yandex DataLens |
 | **BaaS** | Блокчейн как услуга | Azure Blockchain Service | - | Amazon Managed Blockchain | - |
 
