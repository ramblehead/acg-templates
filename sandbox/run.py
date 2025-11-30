#!/usr/bin/env python
# Hey Emacs, this is -*- coding: utf-8; mode: python -*-

from pathlib import Path

from autocodegen import Config, generate

if __name__ == "__main__":
    spath = Path(__file__)
    project_name = spath.stem
    project_parent = spath.parent.resolve(strict=True)
    project_root = project_parent / project_name

    project_root.mkdir()

    config = Config(
        project_name=project_name,
        project_root=project_root,
        acg_root=project_parent / "../hop/templates" / project_name,
    )

    generate("poetry-pyside-starter", config)
