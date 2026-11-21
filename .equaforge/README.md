# Toolbox publishing toolkit

These scripts were generated for `EquaForgeAerospace` from EquaForge's publishing tools.
Keep `library.json` and `package.mo` at the repository root. The CI checkout path
preserves the Modelica package id even when the GitHub repository has another name.

Pushes and pull requests build preview ZIP/catalog artifacts. Previews allow
NOASSERTION, refuse private manifests, and never create a GitHub release.
To prepare a public release, settle the license, bump the manifest version, commit
and push a matching `vVersion` tag. Run **Toolbox release** from the Actions page,
select **create_draft**, and enter that existing tag. The workflow merges the
latest published catalog and creates an unpublished draft with ZIP/catalog assets.
Network/authentication failures and missing prior catalogs stop the release.
An existing release is never overwritten. Publish the draft yourself after review,
before preparing the next release, so its catalog is included in the next build.

After publication, the stable source URL is:
`https://github.com/OWNER/REPO/releases/latest/download/toolboxes.json`
Choose the actual repository later; nothing in this toolkit configures the app.
Mark each new catalog-bearing release Latest when publishing, including maintenance
releases: the merged catalog contains every version. Do not delete older ZIP assets.

Local preview (write artifacts outside this source folder):
`python .equaforge/ci_toolbox_release.py . --output-dir ../toolbox-preview --repository OWNER/REPO`
For local packaging, keep the source folder named `EquaForgeAerospace`. CI sets this up automatically.

Keep the toolkit outside `distributionFiles`; publish only the package's explicit
distribution list. Regenerate into a fresh staging folder to review toolkit updates.
