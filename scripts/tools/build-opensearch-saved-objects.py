#!/usr/bin/env python3
"""Génère les Saved Objects OpenSearch Dashboards à partir d'une définition déclarative."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

NUMERIC = {
    "byte", "short", "integer", "long", "half_float", "float", "double",
    "scaled_float", "unsigned_long",
}
STRING = {"keyword", "text", "wildcard", "constant_keyword", "ip", "version"}
DATE = {"date", "date_nanos"}
BOOL = {"boolean"}


def compact_json(value: object) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def load_json(path: str) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def field_descriptor(name: str, mapping: dict) -> dict:
    mapping_type = mapping.get("type", "object")
    if mapping_type in NUMERIC:
        ui_type = "number"
    elif mapping_type in DATE:
        ui_type = "date"
    elif mapping_type in BOOL:
        ui_type = "boolean"
    elif mapping_type in STRING:
        ui_type = "string"
    else:
        ui_type = "string"

    searchable = mapping.get("index", True) is not False and mapping_type not in {"object", "nested"}
    aggregatable = searchable and mapping_type in (
        NUMERIC | DATE | BOOL | {"keyword", "constant_keyword", "ip", "version"}
    )
    return {
        "count": 0,
        "name": name,
        "type": ui_type,
        "esTypes": [mapping_type],
        "scripted": False,
        "searchable": searchable,
        "aggregatable": aggregatable,
        "readFromDocValues": aggregatable,
    }


def base_search_source() -> dict:
    return {
        "query": {"query": "", "language": "kuery"},
        "filter": [],
        "indexRefName": "kibanaSavedObjectMeta.searchSourceJSON.index",
    }


def donut_terms(item: dict) -> dict:
    return {
        "title": item["title"],
        "type": "pie",
        "params": {
            "type": "pie",
            "addTooltip": True,
            "addLegend": True,
            "legendPosition": "right",
            "isDonut": True,
            "labels": {"show": True, "values": True, "last_level": True, "truncate": 100},
        },
        "aggs": [
            {"id": "1", "enabled": True, "type": "count", "schema": "metric", "params": {}},
            {
                "id": "2",
                "enabled": True,
                "type": "terms",
                "schema": "segment",
                "params": {
                    "field": item["field"],
                    "size": item.get("size", 10),
                    "order": "desc",
                    "orderBy": "1",
                    "otherBucket": False,
                    "otherBucketLabel": "Autres",
                    "missingBucket": False,
                    "missingBucketLabel": "Manquant",
                },
            },
        ],
    }


def histogram_params(mode: str = "normal") -> dict:
    return {
        "type": "histogram",
        "grid": {"categoryLines": False, "valueAxis": None},
        "categoryAxes": [
            {
                "id": "CategoryAxis-1",
                "type": "category",
                "position": "bottom",
                "show": True,
                "style": {},
                "scale": {"type": "linear"},
                "labels": {"show": True, "rotate": 0, "filter": True, "truncate": 100},
                "title": {},
            }
        ],
        "valueAxes": [
            {
                "id": "ValueAxis-1",
                "name": "LeftAxis-1",
                "type": "value",
                "position": "left",
                "show": True,
                "style": {},
                "scale": {"type": "linear", "mode": "normal"},
                "labels": {"show": True, "rotate": 0, "filter": False, "truncate": 100},
                "title": {},
            }
        ],
        "seriesParams": [
            {
                "show": True,
                "type": "histogram",
                "mode": mode,
                "data": {"label": "Valeur", "id": "1"},
                "valueAxis": "ValueAxis-1",
                "drawLinesBetweenPoints": True,
                "showCircles": True,
            }
        ],
        "addTooltip": True,
        "addLegend": True,
        "legendPosition": "right",
        "times": [],
        "addTimeMarker": False,
        "orderBucketsBySum": True,
    }


def histogram_sum_12h(item: dict) -> dict:
    return {
        "title": item["title"],
        "type": "histogram",
        "params": histogram_params("normal"),
        "aggs": [
            {
                "id": "1",
                "enabled": True,
                "type": "sum",
                "schema": "metric",
                "params": {"field": item["field"], "customLabel": "Octets envoyés"},
            },
            {
                "id": "2",
                "enabled": True,
                "type": "date_histogram",
                "schema": "segment",
                "params": {
                    "field": item.get("time_field", "@timestamp"),
                    "interval": "12h",
                    "min_doc_count": 1,
                    "extended_bounds": {},
                    "customLabel": "Tranche de 12 h",
                },
            },
        ],
    }


def histogram_top_terms_12h(item: dict) -> dict:
    params = histogram_params("stacked")
    params["seriesParams"][0]["data"]["label"] = "Requêtes"
    return {
        "title": item["title"],
        "type": "histogram",
        "params": params,
        "aggs": [
            {
                "id": "1",
                "enabled": True,
                "type": "count",
                "schema": "metric",
                "params": {"customLabel": "Requêtes"},
            },
            {
                "id": "2",
                "enabled": True,
                "type": "date_histogram",
                "schema": "segment",
                "params": {
                    "field": item.get("time_field", "@timestamp"),
                    "interval": "12h",
                    "min_doc_count": 1,
                    "extended_bounds": {},
                    "customLabel": "Tranche de 12 h",
                },
            },
            {
                "id": "3",
                "enabled": True,
                "type": "terms",
                "schema": "group",
                "params": {
                    "field": item["field"],
                    "size": item.get("size", 5),
                    "order": "desc",
                    "orderBy": "1",
                    "otherBucket": False,
                    "otherBucketLabel": "Autres",
                    "missingBucket": False,
                    "missingBucketLabel": "Manquant",
                    "customLabel": "URL",
                },
            },
        ],
    }


def build_objects(manifest: dict, index_template: dict) -> list[dict]:
    if manifest.get("schema_version") != 1:
        raise ValueError("schema_version=1 attendu")

    index_pattern = manifest["index_pattern"]
    properties = index_template["template"]["mappings"]["properties"]
    required_fields = {index_pattern["time_field"]}
    for visualization in manifest["visualizations"]:
        required_fields.add(visualization["field"])
        required_fields.add(visualization.get("time_field", index_pattern["time_field"]))
    missing = sorted(required_fields - set(properties))
    if missing:
        raise ValueError("Champs absents du mapping : " + ", ".join(missing))

    fields = [field_descriptor(name, properties[name]) for name in sorted(properties)]
    objects = [
        {
            "attributes": {
                "fields": compact_json(fields),
                "timeFieldName": index_pattern["time_field"],
                "title": index_pattern["title"],
            },
            "id": index_pattern["id"],
            "migrationVersion": {"index-pattern": "7.6.0"},
            "references": [],
            "type": "index-pattern",
        }
    ]

    builders = {
        "donut_terms": donut_terms,
        "histogram_sum_12h": histogram_sum_12h,
        "histogram_top_terms_12h": histogram_top_terms_12h,
    }
    visualization_ids: set[str] = set()
    for visualization in manifest["visualizations"]:
        visualization_id = visualization["id"]
        if visualization_id in visualization_ids:
            raise ValueError(f"ID visualisation dupliqué : {visualization_id}")
        visualization_ids.add(visualization_id)
        kind = visualization["kind"]
        if kind not in builders:
            raise ValueError(f"Type de visualisation inconnu : {kind}")
        state = builders[kind](visualization)
        objects.append(
            {
                "attributes": {
                    "description": "Géré automatiquement par le dépôt P5.",
                    "kibanaSavedObjectMeta": {"searchSourceJSON": compact_json(base_search_source())},
                    "title": visualization["title"],
                    "uiStateJSON": "{}",
                    "version": 1,
                    "visState": compact_json(state),
                },
                "id": visualization_id,
                "migrationVersion": {"visualization": "7.10.0"},
                "references": [
                    {
                        "id": index_pattern["id"],
                        "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
                        "type": "index-pattern",
                    }
                ],
                "type": "visualization",
            }
        )

    dashboard = manifest["dashboard"]
    panels = []
    references = []
    for number, panel in enumerate(dashboard["panels"]):
        visualization_id = panel["visualization_id"]
        if visualization_id not in visualization_ids:
            raise ValueError(f"Panel vers visualisation inconnue : {visualization_id}")
        panel_name = f"panel_{number}"
        panels.append(
            {
                "version": "2.19.0",
                "gridData": {
                    "x": panel["x"], "y": panel["y"], "w": panel["w"], "h": panel["h"], "i": panel_name
                },
                "panelIndex": panel_name,
                "embeddableConfig": {},
                "panelRefName": panel_name,
            }
        )
        references.append({"id": visualization_id, "name": panel_name, "type": "visualization"})

    objects.append(
        {
            "attributes": {
                "description": dashboard["description"],
                "hits": 0,
                "kibanaSavedObjectMeta": {
                    "searchSourceJSON": compact_json({"query": {"query": "", "language": "kuery"}, "filter": []})
                },
                "optionsJSON": compact_json({"hidePanelTitles": False, "useMargins": True}),
                "panelsJSON": compact_json(panels),
                "timeRestore": True,
                "timeFrom": dashboard.get("time_from", "now-30d"),
                "timeTo": dashboard.get("time_to", "now"),
                "title": dashboard["title"],
                "version": 1,
            },
            "id": dashboard["id"],
            "migrationVersion": {"dashboard": "7.9.3"},
            "references": references,
            "type": "dashboard",
        }
    )
    return objects


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--index-template", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    try:
        objects = build_objects(load_json(args.manifest), load_json(args.index_template))
    except (KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
        raise SystemExit(f"Définition Dashboard as Code invalide : {exc}") from exc

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        "\n".join(compact_json(obj) for obj in objects) + "\n",
        encoding="utf-8",
    )
    print(f"{len(objects)} Saved Objects générés : {output}")


if __name__ == "__main__":
    main()
