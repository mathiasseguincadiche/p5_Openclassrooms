import { ChangeDetectionStrategy, Component } from '@angular/core';

interface ProjectStage {
  readonly step: string;
  readonly title: string;
  readonly detail: string;
  readonly status: 'Prêt' | 'À exécuter';
}

interface Capability {
  readonly title: string;
  readonly description: string;
  readonly proof: string;
}

@Component({
  selector: 'app-root',
  standalone: true,
  templateUrl: './app.component.html',
  styleUrl: './app.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AppComponent {
  protected readonly stages: readonly ProjectStage[] = [
    {
      step: '0A',
      title: 'Runtime WSL2',
      detail: 'Ubuntu 26.04 sous WSL2, systemd actif et workspace sur filesystem Linux local.',
      status: 'Prêt',
    },
    {
      step: '0B',
      title: 'AWS Ready',
      detail: 'Compte, région, quota, budget et garde-fous validés.',
      status: 'Prêt',
    },
    {
      step: '1',
      title: 'Terraform + Ansible',
      detail: 'Infrastructure EC2 et déploiement de cette application avec NGINX.',
      status: 'À exécuter',
    },
    {
      step: '2',
      title: 'OpenSearch',
      detail: 'Ingestion des logs NGINX et création des trois visualisations.',
      status: 'À exécuter',
    },
    {
      step: '3',
      title: 'HAProxy',
      detail: 'Round-robin, health checks, panne contrôlée et reprise.',
      status: 'À exécuter',
    },
  ];

  protected readonly capabilities: readonly Capability[] = [
    {
      title: 'Infrastructure reproductible',
      description: 'Trois modules Terraform distincts, verrouillés sur le compte AWS attendu.',
      proof: 'terraform validate + plan relu',
    },
    {
      title: 'Configuration idempotente',
      description: 'Ansible installe NGINX et déploie le même artefact Angular à chaque exécution.',
      proof: 'deuxième playbook sans changement',
    },
    {
      title: 'Observabilité compréhensible',
      description: 'Les logs NGINX sont convertis, typés, importés et vérifiés avant le dashboard.',
      proof: 'index + agrégations + captures',
    },
    {
      title: 'Disponibilité démontrée',
      description: 'HAProxy répartit les requêtes et retire automatiquement un backend indisponible.',
      proof: 'avant, panne, reprise',
    },
  ];

  protected readonly currentYear = new Date().getFullYear();
}
