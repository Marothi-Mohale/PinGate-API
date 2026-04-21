# PinGate Identity Setup Guide

Senior mentoring notes for the foundation phase of the project.

This document captures what we built, why we built it that way, and the senior-level thinking behind each choice. The goal is not only to remember the commands, but to remember the engineering intent behind them.

## 1. The posture we took from the start

- We did not jump straight into controllers or database tables.
- We first verified the environment, then created the architecture skeleton, then wired dependencies, then validated the build.
- This is a senior habit: verify the toolchain, create clear boundaries, then build on a stable foundation.
- We treated the codebase as a system, not just a collection of files.

## 2. Environment verification

### Command: check the .NET SDK

    dotnet --version

- What it does: prints the installed .NET SDK version.
- Why we ran it: to confirm the machine was ready before creating anything.
- What we learned: the machine had .NET SDK 10.0.201 installed.
- Senior lesson: never assume the environment is correct. Verify first.

## 3. Create the solution container

### Command: create the solution

    dotnet new sln -n PinGate.Identity

- What it does: creates the top-level solution container for the system.
- What appeared on disk: PinGate.Identity.slnx.
- Why we did it: this project is bigger than one executable; it needs multiple projects grouped together.
- Senior lesson: the solution is the blueprint for the whole building.

## 4. Create the Domain project

### Command: create the business core

    dotnet new classlib -n PinGate.Identity.Domain -o src/PinGate.Identity.Domain

- What it does: creates a class library for the domain layer.
- Why this layer exists: it holds business concepts and business rules.
- What will live here later: CustomerIdentity, OtpChallenge, SessionToken, TrustedDevice, LoginAttempt, FraudFlag.
- What should not live here: controllers, HTTP code, Redis, database code, EF Core mappings.
- Senior lesson: Domain is the business truth and should be the most independent layer.

### File inspection: Domain project file

    src\PinGate.Identity.Domain\PinGate.Identity.Domain.csproj

- Project Sdk="Microsoft.NET.Sdk": standard SDK for a class library.
- TargetFramework net10.0: the project targets .NET 10.
- ImplicitUsings enable: common namespaces are auto-included.
- Nullable enable: nullable reference type checks are on.
- Senior lesson: strong developers inspect generated files instead of treating templates as magic.

## 5. Create the Application project

### Command: create the use-case layer

    dotnet new classlib -n PinGate.Identity.Application -o src/PinGate.Identity.Application

- What it does: creates a class library for business workflows and use cases.
- Why this layer exists: it coordinates actions such as request OTP, verify OTP, refresh session, logout, list sessions, and get login history.
- What belongs here: commands, queries, DTOs, interfaces, orchestration logic.
- What should not belong here: controllers or direct infrastructure details.
- Senior lesson: Application is where the business acts.

### File inspection: Application project file

    src\PinGate.Identity.Application\PinGate.Identity.Application.csproj

- It had the same baseline settings as Domain.
- That taught us an important lesson: projects can share the same technical template while serving very different architectural roles.

## 6. Create the Infrastructure project

### Command: create the technical implementation layer

    dotnet new classlib -n PinGate.Identity.Infrastructure -o src/PinGate.Identity.Infrastructure

- What it does: creates a class library for technology-facing implementations.
- Why this layer exists: it will hold persistence, Redis integration, token generation, logging, and background services.
- What will live here later: DbContext, repository implementations, Redis OTP storage, audit log plumbing, session persistence, hosted cleanup services.
- Senior lesson: Infrastructure is where the system talks to external technology.

### File inspection: Infrastructure project file

    src\PinGate.Identity.Infrastructure\PinGate.Identity.Infrastructure.csproj

- It also used Microsoft.NET.Sdk with net10.0, implicit usings, and nullable checks.
- Senior lesson: architecture is about responsibility, not just about project templates.

## 7. Create the API project

### Command: create the HTTP host

    dotnet new webapi -n PinGate.Identity.Api -o src/PinGate.Identity.Api --use-controllers

- What it does: creates an ASP.NET Core Web API project using controllers.
- Why we used controllers: they make routing and request handling explicit, which is excellent for learning and common in enterprise codebases.
- Why this layer exists: it exposes the HTTP endpoints for the identity and OTP service.
- Senior lesson: the API is the front door, not the brain.

### File inspection: API project file

    src\PinGate.Identity.Api\PinGate.Identity.Api.csproj

- Project Sdk="Microsoft.NET.Sdk.Web": this is a web host, not a simple class library.
- PackageReference Microsoft.AspNetCore.OpenApi: enables OpenAPI support for documentation and discovery.
- Senior lesson: web projects have different runtime responsibilities than class libraries.

### File inspection: Program.cs

    src\PinGate.Identity.Api\Program.cs

- WebApplication.CreateBuilder(args): starts building the application host.
- AddControllers(): enables controller support.
- AddOpenApi(): registers OpenAPI services.
- Build(): creates the web app.
- MapOpenApi() in development: exposes OpenAPI only in development.
- UseHttpsRedirection(): encourages secure transport.
- UseAuthorization(): adds authorization middleware into the request pipeline.
- MapControllers(): exposes controller routes.
- Run(): starts the app.
- Senior lesson: Program.cs is the assembly point of the application.

### File inspection: WeatherForecastController

    src\PinGate.Identity.Api\Controllers\WeatherForecastController.cs

- ApiController attribute: turns the class into an API controller with API-specific behavior.
- Route("[controller]"): maps the route based on the controller name.
- HttpGet attribute: marks the action as a GET endpoint.
- ControllerBase: the correct base class for APIs without views.
- Senior lesson: the sample controller is only a placeholder. Real business logic must not stay inside toy controllers.

## 8. Create the test project

### Command: create the test safety net

    dotnet new xunit -n PinGate.Identity.Tests -o tests/PinGate.Identity.Tests

- What it does: creates an xUnit test project.
- Why we created it early: testing should shape design from the beginning, especially in a security-sensitive service.
- Senior lesson: tests are not a phase at the end; they are part of the architecture.

### File inspection: test project file

    tests\PinGate.Identity.Tests\PinGate.Identity.Tests.csproj

- Microsoft.NET.Test.Sdk: core test execution support.
- xunit: the test framework.
- xunit.runner.visualstudio: test runner integration.
- coverlet.collector: code coverage collection.
- IsPackable false: the project is for verification, not packaging.
- Senior lesson: test projects have a different purpose and therefore a different dependency profile.

## 9. Add projects to the solution

### Commands: enroll each project into the system

    dotnet sln PinGate.Identity.slnx add src/PinGate.Identity.Domain/PinGate.Identity.Domain.csproj
    dotnet sln PinGate.Identity.slnx add src/PinGate.Identity.Application/PinGate.Identity.Application.csproj
    dotnet sln PinGate.Identity.slnx add src/PinGate.Identity.Infrastructure/PinGate.Identity.Infrastructure.csproj
    dotnet sln PinGate.Identity.slnx add src/PinGate.Identity.Api/PinGate.Identity.Api.csproj
    dotnet sln PinGate.Identity.slnx add tests/PinGate.Identity.Tests/PinGate.Identity.Tests.csproj

- What these commands do: register each project inside the solution.
- Why this matters: a project can exist physically on disk but still not be part of the overall solution structure.
- What changed: the solution now knew about all five projects and could manage them together.
- Senior lesson: creating a project builds a room; adding it to the solution adds that room to the building blueprint.

## 10. Add project references

Project references enforce dependency direction. This is where architecture stops being only a diagram and starts being enforced by the compiler.

### Command: Application depends on Domain

    dotnet add src/PinGate.Identity.Application/PinGate.Identity.Application.csproj reference src/PinGate.Identity.Domain/PinGate.Identity.Domain.csproj

- Why it is correct: use cases need the business concepts and rules from the domain.
- Senior lesson: Application stands on Domain.

### Command: Infrastructure depends on Application

    dotnet add src/PinGate.Identity.Infrastructure/PinGate.Identity.Infrastructure.csproj reference src/PinGate.Identity.Application/PinGate.Identity.Application.csproj

- Why it is correct: Infrastructure will implement contracts defined by Application.
- Example later: Application may define IOtpStore, Infrastructure may implement RedisOtpStore.
- Senior lesson: outer layers implement what inner layers require.

### Command: Infrastructure depends on Domain

    dotnet add src/PinGate.Identity.Infrastructure/PinGate.Identity.Infrastructure.csproj reference src/PinGate.Identity.Domain/PinGate.Identity.Domain.csproj

- Why it is correct: persistence and technical implementations may need domain entities and value objects.
- Senior lesson: Infrastructure supports the business model without owning it.

### Command: API depends on Application

    dotnet add src/PinGate.Identity.Api/PinGate.Identity.Api.csproj reference src/PinGate.Identity.Application/PinGate.Identity.Application.csproj

- Why it is correct: controllers should call use cases, not contain the real business workflow logic.
- Senior lesson: thin controllers, strong application layer.

### Command: API depends on Infrastructure

    dotnet add src/PinGate.Identity.Api/PinGate.Identity.Api.csproj reference src/PinGate.Identity.Infrastructure/PinGate.Identity.Infrastructure.csproj

- Why it is correct: the API acts as the composition root and wires concrete implementations during startup.
- Senior lesson: the API assembles the runtime but should not absorb the technical logic itself.

### Command: Tests depend on Application

    dotnet add tests/PinGate.Identity.Tests/PinGate.Identity.Tests.csproj reference src/PinGate.Identity.Application/PinGate.Identity.Application.csproj

- Why it is correct: many of the best tests target business workflows directly without going through HTTP.
- Senior lesson: test use cases at the application layer for speed and clarity.

### Command: Tests depend on Domain

    dotnet add tests/PinGate.Identity.Tests/PinGate.Identity.Tests.csproj reference src/PinGate.Identity.Domain/PinGate.Identity.Domain.csproj

- Why it is correct: domain rules deserve direct, focused tests.
- Senior lesson: test pure rules close to the core.

## 11. Build the full solution

### Command: validate the foundation

    dotnet build PinGate.Identity.slnx

- What it does: restores dependencies and compiles the whole solution.
- Result we observed: all projects built successfully.
- Why we do this before building features: it confirms the architecture skeleton is healthy before more complexity is added.
- Senior lesson: validate the foundation before building the house higher.

## 12. The architecture you created

The dependency map after wiring was:

- Application -> Domain
- Infrastructure -> Application
- Infrastructure -> Domain
- Api -> Application
- Api -> Infrastructure
- Tests -> Application
- Tests -> Domain

This means:

- Domain is the core truth.
- Application orchestrates the use cases.
- Infrastructure provides technical implementations.
- Api exposes the system over HTTP and assembles the runtime.
- Tests verify the rules and flows.

## 13. The mental model to remember

Use these five words:

- Domain = truth
- Application = flow
- Infrastructure = implementation
- Api = entry
- Tests = trust

Or remember this sentence:

Core rules stay inside. Technical details stay outside.

## 14. The anti-patterns we deliberately avoided

- Putting business logic in controllers.
- Letting controllers talk straight to the database.
- Mixing Redis logic into endpoint classes.
- Treating testing as something to do at the end.
- Letting the core business layer depend on outer technical layers.

Senior lesson: good architecture is mostly about controlling who is allowed to know about whom.

## 15. What you should be able to explain now

By the end of this foundation phase, you should be able to explain:

- why we created a solution before building features
- why Domain and Application are separate
- why Infrastructure is isolated
- why the API is the composition root
- why tests were created before business code
- why dependency direction matters
- why a clean build is a milestone

## 16. Full command summary

### Environment

    dotnet --version

### Solution

    dotnet new sln -n PinGate.Identity

### Projects

    dotnet new classlib -n PinGate.Identity.Domain -o src/PinGate.Identity.Domain
    dotnet new classlib -n PinGate.Identity.Application -o src/PinGate.Identity.Application
    dotnet new classlib -n PinGate.Identity.Infrastructure -o src/PinGate.Identity.Infrastructure
    dotnet new webapi -n PinGate.Identity.Api -o src/PinGate.Identity.Api --use-controllers
    dotnet new xunit -n PinGate.Identity.Tests -o tests/PinGate.Identity.Tests

### Add projects to the solution

    dotnet sln PinGate.Identity.slnx add src/PinGate.Identity.Domain/PinGate.Identity.Domain.csproj
    dotnet sln PinGate.Identity.slnx add src/PinGate.Identity.Application/PinGate.Identity.Application.csproj
    dotnet sln PinGate.Identity.slnx add src/PinGate.Identity.Infrastructure/PinGate.Identity.Infrastructure.csproj
    dotnet sln PinGate.Identity.slnx add src/PinGate.Identity.Api/PinGate.Identity.Api.csproj
    dotnet sln PinGate.Identity.slnx add tests/PinGate.Identity.Tests/PinGate.Identity.Tests.csproj

### Add project references

    dotnet add src/PinGate.Identity.Application/PinGate.Identity.Application.csproj reference src/PinGate.Identity.Domain/PinGate.Identity.Domain.csproj
    dotnet add src/PinGate.Identity.Infrastructure/PinGate.Identity.Infrastructure.csproj reference src/PinGate.Identity.Application/PinGate.Identity.Application.csproj
    dotnet add src/PinGate.Identity.Infrastructure/PinGate.Identity.Infrastructure.csproj reference src/PinGate.Identity.Domain/PinGate.Identity.Domain.csproj
    dotnet add src/PinGate.Identity.Api/PinGate.Identity.Api.csproj reference src/PinGate.Identity.Application/PinGate.Identity.Application.csproj
    dotnet add src/PinGate.Identity.Api/PinGate.Identity.Api.csproj reference src/PinGate.Identity.Infrastructure/PinGate.Identity.Infrastructure.csproj
    dotnet add tests/PinGate.Identity.Tests/PinGate.Identity.Tests.csproj reference src/PinGate.Identity.Application/PinGate.Identity.Application.csproj
    dotnet add tests/PinGate.Identity.Tests/PinGate.Identity.Tests.csproj reference src/PinGate.Identity.Domain/PinGate.Identity.Domain.csproj

### Validate the foundation

    dotnet build PinGate.Identity.slnx

## 17. Final encouragement

This phase may feel simple because it was mostly setup, but it was not trivial. You practiced professional habits that many developers skip:

- verifying tools
- reading generated files
- separating responsibilities early
- enforcing architecture with project references
- validating the full build before feature work

That is how dependable engineers work. The code is still small, but the thinking is already senior.
