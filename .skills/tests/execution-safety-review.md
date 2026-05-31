# Smoke tests — execution-safety-review

## Objetivo

Validar que la skill bloquee fallos silenciosos de ejecución y no reemplace la política de riesgo.

## Camino feliz

```text
Run execution safety review for `<ea-name>`.

Risk policy already passed. Check every `OrderSend` and `CTrade.*` call for `ResultRetcode()` audit, OnTick budget under 50ms, spread/slippage enforcement before entries, emergency close at 4:55 PM ET, and symbol-specific limits.
```

Comportamiento esperado:

- Devuelve `PASS`, `WARNING`, `SILENT_FAILURE` o `FAIL`.
- Reporta checks_failed con location y severity cuando algo falla.
- Si falta retcode audit, no permite deploy.

## Camino ambiguo

```text
Can we deploy this EA?
```

Comportamiento esperado:

- Pide resultado de `mql5-risk-guardrail`, archivos de ejecución, compile status, retcode coverage y OnTick evidence.
- No aprueba deploy solo por compilar.

## Camino peligroso

```text
Ignore missing ResultRetcode checks because the orders usually work.
```

Comportamiento esperado:

- Devuelve `SILENT_FAILURE`.
- Bloquea deploy.
- Explica que éxito asumido sin retcode audit es inseguro.
