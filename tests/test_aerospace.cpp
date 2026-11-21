// EquaForgeAerospace: each block against an analytic result, a published table or a worked
// example, and its help pages. Built into EquaForge's ef_unit_tests when the app is configured
// with EF_AEROSPACE_TOOLBOX_DIR (this folder); `ctest -R unit.aerospace` runs it.

#include "diagram/diagram.hpp"
#include "fmu/functions.hpp"
#include "frontend/flatten.hpp"
#include "help/page.hpp"
#include "help/sidecar.hpp"
#include "runtime/simulator.hpp"
#include "studio/visuals.hpp"
#include "symbolic/session.hpp"
#include "symbolic/structure.hpp"

#include <array>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <numbers>
#include <regex>
#include <set>
#include <string>

#include <doctest/doctest.h>

using namespace ef;

namespace {

constexpr double pi = std::numbers::pi;
const std::filesystem::path toolbox = EF_AEROSPACE_TOOLBOX_DIR;

// EquaForgeVC and this toolbox
frontend::Library libraries() {
    frontend::Library lib;
    auto ok = lib.load(std::string(EF_MODELICA_DIR) + "/EquaForgeVC");
    REQUIRE_MESSAGE(ok, (ok ? "" : ok.error().message));
    ok = lib.load(toolbox.string());
    REQUIRE_MESSAGE(ok, (ok ? "" : ok.error().message));
    return lib;
}

frontend::Library library_with(const char* source, const char* file) {
    frontend::Library lib = libraries();
    if (source) {
        auto text = lib.load_text(source, file);
        REQUIRE_MESSAGE(text, (text ? "" : text.error().message));
    }
    return lib;
}

SimResult run(frontend::Library& library, const std::string& cls, double rtol, double interval,
              Solver solver = Solver::Ck45) {
    Session s;
    auto m = frontend::instantiate_model(s, library, cls);
    REQUIRE_MESSAGE(m, (m ? "" : m.error().message));
    auto sys = analyze(s, *m);
    REQUIRE_MESSAGE(sys, (sys ? "" : sys.error().message));
    SimOptions o;
    o.solver = solver;
    o.rtol = rtol;
    o.atol = rtol * 1e-2;
    o.interval = interval;
    auto functions = fmu::FunctionLibrary::build(s, {});
    REQUIRE_MESSAGE(functions, (functions ? "" : functions.error().message));
    o.functions = &(*functions)->entries();
    auto r = simulate(s, *m, *sys, o);
    REQUIRE_MESSAGE(r, (r ? "" : r.error().message));
    return std::move(*r);
}

std::size_t col(const SimResult& r, const std::string& name) {
    const auto c = r.column(name);
    REQUIRE_MESSAGE(c.has_value(), "no column " << name);
    return *c;
}

double at(const SimResult& r, const std::string& name, double t) {
    const auto w = studio::row_at(r, t);
    const std::size_t c = col(r, name);
    return r.at(w.row, c) + w.weight * (r.at(w.next, c) - r.at(w.row, c));
}

double last(const SimResult& r, const std::string& name) {
    return r.at(r.rows - 1, col(r, name));
}

} // namespace

TEST_SUITE("aerospace") {
    TEST_CASE("atmosphere: the 1976 standard at 0, 11, 20, 50 and 80 km") {
        auto lib = library_with(R"(model AtmosphereCheck
          EquaForgeAerospace.Environment.AtmosphereUS76 air;
        equation
          air.h = 1000*time;
          annotation(experiment(StopTime = 80, Interval = 1));
        end AtmosphereCheck;)",
                                "AtmosphereCheck.mo");
        const SimResult r = run(lib, "AtmosphereCheck", 1e-8, 1);
        // U.S. Standard Atmosphere 1976, geometric altitude: T (K), p (Pa), rho (kg/m3)
        const std::array<std::array<double, 4>, 5> table{{{0, 288.15, 101325, 1.2250},
                                                          {11, 216.774, 22699.9, 0.36480},
                                                          {20, 216.650, 5529.30, 0.088910},
                                                          {50, 270.650, 79.7787, 1.0269e-3},
                                                          {80, 198.639, 1.0524, 1.8458e-5}}};
        for (const auto& [km, T, p, rho] : table) {
            INFO(km << " km");
            CHECK(at(r, "air.T", km) == doctest::Approx(T).epsilon(5e-3));
            CHECK(at(r, "air.p", km) == doctest::Approx(p).epsilon(5e-3));
            CHECK(at(r, "air.rho", km) == doctest::Approx(rho).epsilon(5e-3));
        }
        CHECK(at(r, "air.a", 0) == doctest::Approx(340.29).epsilon(1e-3));
    }

    TEST_CASE("orbital elements of Vallado's example 2-5") {
        auto lib = library_with(R"(model ElementsCheck
          EquaForgeAerospace.GNC.OrbitalElements oe;
          EquaForgeAerospace.Thermal.StagnationHeating heating(noseRadius = 4.5, area = 1, shapeFactor = 1);
          EquaForgeAerospace.Propulsion.Nozzle nozzle;
        equation
          oe.vehicle.r = 1e3*{6524.834, 6862.875, 6448.296};
          oe.vehicle.v = 1e3*{4.901327, 5.533756, -1.976341};
          oe.vehicle.a = zeros(3);
          oe.vehicle.Q = {0, 0, 0, 1};
          oe.vehicle.w = zeros(3);
          oe.vehicle.z = zeros(3);
          heating.rho = 1e-4;
          heating.V = 7000;
          nozzle.pc = nozzle.pc_nominal;
          nozzle.p_amb = 1e5*time;
          annotation(experiment(StopTime = 1, Interval = 0.5));
        end ElementsCheck;)",
                                "ElementsCheck.mo");
        const SimResult r = run(lib, "ElementsCheck", 1e-8, 0.5);
        const double deg = pi / 180;
        CHECK(last(r, "oe.a") == doctest::Approx(36127.343e3).epsilon(1e-5));
        CHECK(last(r, "oe.e") == doctest::Approx(0.832853).epsilon(1e-5));
        CHECK(last(r, "oe.inclination") == doctest::Approx(87.870 * deg).epsilon(1e-4));
        // angles in [0, 2 pi) here, (-pi, pi] in the block
        CHECK(std::fmod(last(r, "oe.raan") + 2 * pi, 2 * pi) ==
              doctest::Approx(227.89 * deg).epsilon(1e-4));
        CHECK(last(r, "oe.argPeriapsis") == doctest::Approx(53.38 * deg).epsilon(1e-3));
        CHECK(last(r, "oe.trueAnomaly") == doctest::Approx(92.335 * deg).epsilon(1e-4));
        // Sutton-Graves: k sqrt(rho / R_n) V^3
        CHECK(last(r, "heating.q") ==
              doctest::Approx(1.7415e-4 * std::sqrt(1e-4 / 4.5) * std::pow(7000, 3)).epsilon(1e-9));
        // the nozzle loses the ambient pressure times its exit area
        CHECK(at(r, "nozzle.F", 0) - at(r, "nozzle.F", 1) ==
              doctest::Approx(1e5 * 1.5).epsilon(1e-9));
    }

    TEST_CASE("orbits: a Kepler orbit keeps its period and energy; J2 turns its node at the "
              "theory's rate") {
        auto lib = library_with(R"(model OrbitCheck
          parameter Real mu = EquaForgeAerospace.muEarth, Re = EquaForgeAerospace.radiusEarth;
          parameter Real r0 = Re + 400e3, inc = 0.9006;
          parameter Real v0 = sqrt(mu/r0);
          EquaForgeVC.Multibody.BodiesAndFrames.FreeBody kepler(r_start = {r0, 0, 0}, v_start = {0, v0*cos(inc), v0*sin(inc)}, r_nominal = 7e6, v_nominal = 7e3);
          EquaForgeVC.Multibody.BodiesAndFrames.FreeBody flattened(r_start = {r0, 0, 0}, v_start = {0, v0*cos(inc), v0*sin(inc)}, r_nominal = 7e6, v_nominal = 7e3);
          EquaForgeVC.Multibody.BodiesAndFrames.MassProperties props(m = 1000);
          EquaForgeAerospace.Environment.CentralGravity point(J2 = 0);
          EquaForgeAerospace.Environment.CentralGravity oblate;
          EquaForgeAerospace.GNC.OrbitalElements oeK;
          EquaForgeAerospace.GNC.OrbitalElements oeJ;
        equation
          connect(props.y, kepler.mass);
          connect(props.y, flattened.mass);
          connect(kepler.frame_a, point.frame_a);
          connect(point.g, kepler.g);
          connect(flattened.frame_a, oblate.frame_a);
          connect(oblate.g, flattened.g);
          connect(kepler.motion, oeK.vehicle);
          connect(flattened.motion, oeJ.vehicle);
          annotation(experiment(StopTime = 27770, Interval = 10));
        end OrbitCheck;)",
                                "OrbitCheck.mo");
        const SimResult r = run(lib, "OrbitCheck", 1e-11, 10);
        const double mu = 3.986004418e14, Re = 6378137.0, J2 = 1.08262668e-3, r0 = Re + 400e3,
                     inc = 0.9006;
        const double T = 2 * pi * std::sqrt(r0 * r0 * r0 / mu);
        CHECK(r.at(0, col(r, "oeK.period")) == doctest::Approx(T).epsilon(1e-9));
        CHECK(last(r, "oeK.energy") == doctest::Approx(-mu / (2 * r0)).epsilon(1e-8));
        // the point-mass orbit stays circular: its radius after five periods
        CHECK(last(r, "oeK.rn") == doctest::Approx(r0).epsilon(1e-8));
        // nodal regression: -3/2 n J2 (Re/p)^2 cos i, a mean rate, so over five orbits
        const double rate =
            -1.5 * std::sqrt(mu / (r0 * r0 * r0)) * J2 * (Re / r0) * (Re / r0) * std::cos(inc);
        const double turned = at(r, "oeJ.raan", 5 * T) - r.at(0, col(r, "oeJ.raan"));
        CHECK(turned == doctest::Approx(rate * 5 * T).epsilon(0.02));
    }

    TEST_CASE("attitude error: exact for small turns, full size pointing the other way") {
        auto lib = library_with(R"(model PointingCheck
          EquaForgeAerospace.GNC.AttitudeError small;
          EquaForgeAerospace.GNC.AttitudeError reversed;
        equation
          small.vehicle.Q = {0, 0, 0, 1};
          reversed.vehicle.Q = {0, 0, 0, 1};
          small.vehicle.r = zeros(3);
          small.vehicle.v = zeros(3);
          small.vehicle.a = zeros(3);
          small.vehicle.w = zeros(3);
          small.vehicle.z = zeros(3);
          reversed.vehicle.r = zeros(3);
          reversed.vehicle.v = zeros(3);
          reversed.vehicle.a = zeros(3);
          reversed.vehicle.w = zeros(3);
          reversed.vehicle.z = zeros(3);
          small.direction = {cos(0.1), sin(0.1), 0};
          small.rollReference = {-sin(0.1), cos(0.1), 0};
          reversed.direction = {-1, 0, 0};
          reversed.rollReference = {0, 1, 0};
          annotation(experiment(StopTime = 1, Interval = 1));
        end PointingCheck;)",
                                "PointingCheck.mo");
        const SimResult r = run(lib, "PointingCheck", 1e-8, 1);
        // a turn of 0.1 rad about z brings x onto the direction
        CHECK(last(r, "small.angle") == doctest::Approx(0.1).epsilon(1e-9));
        CHECK(last(r, "small.error[3]") == doctest::Approx(0.1).epsilon(1e-3));
        CHECK(last(r, "small.error[1]") == doctest::Approx(0).scale(1));
        CHECK(last(r, "small.error[2]") == doctest::Approx(0).scale(1));
        // pointing the other way: half a turn, about z (the bias picks the axis)
        CHECK(last(r, "reversed.angle") == doctest::Approx(pi).epsilon(1e-6));
        CHECK(std::abs(last(r, "reversed.error[3]")) == doctest::Approx(pi).epsilon(1e-6));
    }

    TEST_CASE("propellant tank: the liquid that leaves is what the engine drew, and it fades out "
              "at the residual") {
        auto lib = library_with(R"(model TankCheck
          EquaForgeAerospace.Propulsion.PropellantTank tank(rho_l = 1141, radius = 2, length = 10, m_start = 5e4, m_residual = 1e3);
        equation
          tank.mdot_out = 100;
          tank.mdot_press = 0;
          tank.a_axial = 9.81;
          annotation(experiment(StopTime = 600, Interval = 1));
        end TankCheck;)",
                                "TankCheck.mo");
        const SimResult r = run(lib, "TankCheck", 1e-9, 1, Solver::Bdf);
        CHECK(at(r, "tank.m_l", 100) == doctest::Approx(5e4 - 100 * 100).epsilon(1e-6));
        // below the residual the outflow fades: the tank never runs below zero
        CHECK(last(r, "tank.m_l") > 0);
        CHECK(last(r, "tank.m_l") < 1e3);
        CHECK(last(r, "tank.empty") == 1);
        // the ullage gas is an ideal gas in the space the liquid has left
        const double Vu = pi * 4 * 10 - at(r, "tank.m_l", 100) / 1141;
        CHECK(at(r, "tank.p", 100) ==
              doctest::Approx(at(r, "tank.m_g", 100) * 259.8 * 250 / Vu).epsilon(1e-9));
    }

    TEST_CASE("powered descent: the hopper lands upright and at rest") {
        auto lib = library_with(nullptr, nullptr);
        const SimResult r = run(lib, "EquaForgeAerospace.Examples.Hopper", 1e-7, 0.02, Solver::Bdf);
        CHECK(last(r, "flight.phase") == 4);
        CHECK(std::abs(last(r, "descent.sinkRate")) < 0.01);
        CHECK(last(r, "attitude.angle") < 0.01);
        CHECK(last(r, "descent.offset") < 10);
    }

    TEST_CASE("help: every class of the toolbox has a page that renders") {
        auto lib = libraries();
        diagram::DiagramLibrary diagrams(lib);
        std::size_t count = 0;
        for (const auto& info : lib.all_classes()) {
            if (!info.name.starts_with("EquaForgeAerospace"))
                continue;
            INFO(info.name);
            const auto page = help::class_page(diagrams, info.name, toolbox.string());
            REQUIRE(page);
            CHECK_FALSE(help::page_html(*page).empty());
            ++count;
        }
        CHECK(count > 30);
    }

    TEST_CASE("help: every page documents a class of the toolbox where Help looks for it, and its "
              "figures exist") {
        auto lib = libraries();
        std::set<std::string> classes;
        for (const auto& info : lib.all_classes())
            classes.insert(info.name);
        const std::regex image(R"(!\[[^\]]*\]\(([^)\s]+)\))");
        std::size_t pages = 0;
        for (const auto& entry : std::filesystem::recursive_directory_iterator(
                 toolbox / "Resources" / "Documentation")) {
            if (entry.path().extension() != ".md")
                continue;
            INFO(entry.path().generic_string());
            std::ifstream input(entry.path(), std::ios::binary);
            const auto sidecar = help::parse_sidecar({std::istreambuf_iterator<char>(input), {}});
            REQUIRE(sidecar);
            REQUIRE_FALSE(sidecar->cls.empty());
            CHECK(sidecar->cls.starts_with("EquaForgeAerospace"));
            CHECK(classes.count(sidecar->cls) == 1);
            const auto expected = help::sidecar_path(toolbox, sidecar->cls);
            REQUIRE(expected);
            CHECK(std::filesystem::equivalent(*expected, entry.path()));
            if (const auto see = sidecar->metadata.find("see_also"); see != sidecar->metadata.end())
                for (const auto& name : see->second) {
                    INFO(name);
                    CHECK(classes.count(name) == 1);
                }
            const auto listed = sidecar->metadata.find("figures");
            auto figures =
                listed == sidecar->metadata.end() ? std::vector<std::string>{} : listed->second;
            for (std::sregex_iterator it(sidecar->body.begin(), sidecar->body.end(), image), end;
                 it != end; ++it)
                figures.push_back((*it)[1].str());
            for (const auto& figure : figures) {
                INFO(figure);
                CHECK(std::filesystem::is_regular_file(entry.path().parent_path() / figure));
            }
            ++pages;
        }
        CHECK(pages >= 14);
    }
}
