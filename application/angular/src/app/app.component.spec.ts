import { TestBed } from '@angular/core/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { AppComponent } from './app.component';

describe('AppComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AppComponent],
    }).compileComponents();
  });

  function render(): HTMLElement {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    return fixture.nativeElement as HTMLElement;
  }

  it('crée le composant racine', () => {
    const fixture = TestBed.createComponent(AppComponent);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('affiche le titre principal attendu', () => {
    const element = render();
    expect(element.querySelector('h1')?.textContent?.trim()).toBe(
      'Déployer et suivre une infrastructure as code',
    );
  });

  it('rend les cinq étapes du parcours et les deux étapes prêtes', () => {
    const element = render();
    expect(element.querySelectorAll('.journey__item')).toHaveLength(5);
    expect(element.querySelectorAll('.status--ready')).toHaveLength(2);

    const readyStatuses = Array.from(element.querySelectorAll('.status--ready')).map(
      (status) => status.textContent?.trim(),
    );
    expect(readyStatuses).toEqual(['Prêt', 'Prêt']);
  });

  it('rend les quatre capacités annoncées', () => {
    const element = render();
    expect(element.querySelectorAll('article.capability')).toHaveLength(4);
  });

  it('conserve les principaux repères d’accessibilité', () => {
    const element = render();
    expect(element.querySelector('main')).not.toBeNull();
    expect(element.querySelector('[aria-label="Technologies principales"]')).not.toBeNull();
    expect(element.querySelector('[aria-label="Résumé du projet"]')).not.toBeNull();
    expect(element.querySelector('[aria-label="Chaîne de déploiement"]')).not.toBeNull();
  });

  it('affiche l’année courante dans le pied de page', () => {
    const element = render();
    expect(element.querySelector('footer')?.textContent).toContain(
      String(new Date().getFullYear()),
    );
  });
});
