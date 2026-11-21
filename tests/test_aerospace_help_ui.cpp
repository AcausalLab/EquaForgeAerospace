// EquaForgeAerospace's Help pages in Studio's Help view: every formula, Mermaid diagram and
// figure draws. Built into EquaForge's ef_help_ui_tests (ctest studio.help) when the app is
// configured with EF_AEROSPACE_TOOLBOX_DIR (this folder). With EF_UI_SHOTS=DIR each whole page
// is saved there, for a person to look at.

#include "studio/catalog.hpp"
#include "studio/diagram_render.hpp"
#include "studio/help_page_view.hpp"

#include <QElapsedTimer>
#include <QTest>
#include <QTextDocument>
#include <QtMath>
#include <algorithm>
#include <memory>
#include <string>

#include <doctest/doctest.h>

using namespace ef::studio;

TEST_CASE("help: the aerospace toolbox's pages draw every formula, diagram and figure") {
    auto catalog = std::make_shared<Catalog>(
        QStringList{bundled_library_dir(), QStringLiteral(EF_AEROSPACE_TOOLBOX_DIR)});
    HelpPageView view;
    view.resize(860, 700);
    view.set_catalog(catalog);
    view.show();
    const auto shots = qEnvironmentVariable("EF_UI_SHOTS");
    for (const char* cls :
         {"EquaForgeAerospace", "EquaForgeAerospace.Environment.CentralGravity",
          "EquaForgeAerospace.Environment.AtmosphereUS76",
          "EquaForgeAerospace.Aerodynamics.BodyAero",
          "EquaForgeAerospace.Propulsion.PropellantTank", "EquaForgeAerospace.Propulsion.Nozzle",
          "EquaForgeAerospace.Propulsion.RocketEngine",
          "EquaForgeAerospace.Propulsion.EngineCluster", "EquaForgeAerospace.GNC.OrbitalElements",
          "EquaForgeAerospace.GNC.AttitudeError", "EquaForgeAerospace.GNC.EntryAttitude",
          "EquaForgeAerospace.GNC.ImpactPointPredictor", "EquaForgeAerospace.GNC.PoweredDescent",
          "EquaForgeAerospace.Thermal.StagnationHeating"}) {
        const std::string name = cls;
        CAPTURE(name);
        REQUIRE(view.show_class(QString::fromLatin1(cls), true));
        QElapsedTimer ready;
        ready.start();
        while (view.busy() && ready.elapsed() < 30000)
            QTest::qWait(20);
        CHECK_FALSE(view.busy());
        // (a block with several inputs has no step response: its page says so instead)
        auto errors = view.resource_errors();
        errors.removeIf([](const QString& e) { return e.contains(QStringLiteral("unit step")); });
        INFO(errors.join(QStringLiteral(" | ")).toStdString());
        CHECK(errors.isEmpty());
        // the Mermaid blocks are drawn, not left as their text
        CHECK_FALSE(view.toPlainText().contains(QStringLiteral("flowchart")));
        if (!shots.isEmpty()) {
            const int height = qCeil(view.document()->size().height()) + 40;
            view.resize(860, std::min(height, 16000));
            QTest::qWait(50);
            CHECK(
                view.grab().save(shots + QStringLiteral("/%1.png").arg(QString::fromLatin1(cls))));
            view.resize(860, 700);
        }
    }
}
