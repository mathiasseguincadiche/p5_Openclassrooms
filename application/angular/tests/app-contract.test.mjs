import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import test from 'node:test';

const componentSource = await readFile(
  new URL('../src/app/app.component.ts', import.meta.url),
  'utf8',
);
const componentTemplate = await readFile(
  new URL('../src/app/app.component.html', import.meta.url),
  'utf8',
);
const bootstrapSource = await readFile(
  new URL('../src/main.ts', import.meta.url),
  'utf8',
);

test('le composant racine conserve le contrat Angular attendu', () => {
  assert.match(componentSource, /standalone:\s*true/);
  assert.match(componentSource, /ChangeDetectionStrategy\.OnPush/);
  assert.equal((componentSource.match(/step:\s*'/g) ?? []).length, 5);
  assert.equal((componentSource.match(/^\s+status:\s*'Prêt',/gm) ?? []).length, 2);
  assert.equal((componentSource.match(/^\s+status:\s*'À exécuter',/gm) ?? []).length, 3);
});

test('l’interface reflète le runtime Windows 11 + WSL2 actuel', () => {
  assert.match(componentSource, /Runtime WSL2/);
  assert.match(componentSource, /Ubuntu 26\.04 sous WSL2/);
  assert.match(componentTemplate, /Ubuntu 26\.04 sous WSL2/);
  assert.doesNotMatch(componentSource, /VM de lab|Ubuntu Server 26\.04/i);
  assert.doesNotMatch(componentTemplate, /VM de lab|construite sur la VM de lab/i);
});

test('le template présente le parcours, les preuves et une structure accessible', () => {
  assert.match(componentTemplate, /<main>/);
  assert.match(componentTemplate, /aria-labelledby="hero-title"/);
  assert.match(componentTemplate, /@for \(stage of stages; track stage\.step\)/);
  assert.match(componentTemplate, /@for \(capability of capabilities; track capability\.title\)/);
  assert.match(componentTemplate, /Aucune étape déclarée terminée sans preuve réelle/);
  assert.doesNotMatch(componentTemplate, /preuve à insérer/i);
});

test('le démarrage Angular échoue explicitement en cas d’erreur', () => {
  assert.match(bootstrapSource, /bootstrapApplication\(AppComponent/);
  assert.match(bootstrapSource, /catch\(\(error(?::\s*unknown)?\)/);
  assert.match(bootstrapSource, /console\.error/);
});
