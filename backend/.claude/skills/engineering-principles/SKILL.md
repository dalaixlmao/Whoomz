---
name: engineering-principles
description: Core software engineering principles — OOP, SOLID, LLD, KISS, DRY, YAGNI, and GoF design patterns. Use when designing classes, writing services, reviewing code structure, or applying design patterns.
---

# Core Engineering Principles

## OOP Pillars

| Pillar | One-line | Apply when |
|---|---|---|
| **Encapsulation** | Hide internals, expose interface | Class has mutable state |
| **Abstraction** | Expose what, hide how | Multiple implementations possible |
| **Inheritance** | Reuse via IS-A hierarchy | True subtype relationship exists |
| **Polymorphism** | Same call, different behaviour | Swappable implementations |

Prefer **composition over inheritance** — inherit only when `B` is genuinely an `A`.

---

## SOLID

**S — Single Responsibility**  
One class, one reason to change. Split `UserService` that also sends emails into `UserService` + `EmailService`.

**O — Open/Closed**  
Open for extension, closed for modification. Add behaviour via new classes/strategies, not by editing existing ones.

**L — Liskov Substitution**  
Subtypes must be usable wherever the base type is expected without breaking callers. If `Square(Rectangle)` breaks `set_width`, it violates LSP.

**I — Interface Segregation**  
Don't force clients to depend on methods they don't use. Split fat interfaces into focused ones.

**D — Dependency Inversion**  
Depend on abstractions, not concretions. Inject dependencies — don't instantiate them inside a class.

```python
# ✅ DI-compliant
class OrderService:
    def __init__(self, repo: OrderRepository):  # abstraction injected
        self.repo = repo
```

---

## KISS · DRY · YAGNI

**KISS** — Keep It Simple. Prefer the obvious solution. Complexity is debt.

**DRY** — Every piece of knowledge has one authoritative source. Extract shared logic, but don't over-abstract incidental similarity.

**YAGNI** — Don't build what you don't need yet. Build for current requirements; refactor when the new requirement actually arrives.

---

## Low-Level Design (LLD)

Steps when designing a class/module:

1. Identify **entities** and their responsibilities
2. Define **relationships** (association, aggregation, composition, inheritance)
3. Apply **SOLID** at every boundary
4. Choose **design patterns** where they reduce complexity
5. Keep interfaces **narrow** — only what callers need

---

## GoF Design Patterns

### Creational
| Pattern | Use |
|---|---|
| **Singleton** | One shared instance (config, DB pool) |
| **Factory Method** | Delegate object creation to subclasses |
| **Abstract Factory** | Create families of related objects |
| **Builder** | Construct complex objects step-by-step |
| **Prototype** | Clone existing objects |

### Structural
| Pattern | Use |
|---|---|
| **Adapter** | Wrap incompatible interface to match expected one |
| **Decorator** | Add behaviour without subclassing |
| **Facade** | Simplify a complex subsystem with one interface |
| **Proxy** | Control access — caching, auth, lazy load |
| **Composite** | Tree structures where leaf and branch are uniform |

### Behavioural
| Pattern | Use |
|---|---|
| **Strategy** | Swap algorithms at runtime |
| **Observer** | Notify dependents on state change (events) |
| **Command** | Encapsulate a request as an object (undo, queue) |
| **Chain of Responsibility** | Pass request along handler chain (middleware) |
| **Template Method** | Skeleton algorithm, steps overridden by subclasses |
| **Repository** | Abstract data access behind a collection-like interface |

---

## Quick Checks Before Committing Code

- Does each class have one clear responsibility? → **SRP**
- Are you editing existing code to add a feature? → **OCP**
- Did you copy-paste logic? → **DRY**
- Did you build something "for later"? → **YAGNI**
- Is the solution harder to explain than the problem? → **KISS**
- Does a subclass change expected behaviour? → **LSP**
- Is a class importing a concrete implementation directly? → **DIP**