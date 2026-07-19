# Calcpad Octave

**Octave-syntax scientific worksheets** — mismo entorno WPF + CLI que
[Calcpad](https://calcpad.eu/), pero el parser lee scripts **`.m` con sintaxis de GNU Octave**
en vez de `.cpd`. Motor MATLAB/Octave nativo en C# con **JIT (Expression Trees)** y **Intel MKL**,
**sin necesidad de instalar Octave**.

> Programa **separado** de [Calcpad Lab](https://github.com/GiorgioBurbanelli89/Calcpad-Lab):
> Lab corre MATLAB estricto; **Calcpad Octave tiene el modo Octave SIEMPRE activo**, así que
> acepta la sintaxis que Octave añade sobre MATLAB y que en Lab daría error.

📥 **Download:** [CalcpadOctave-Setup-1.0.0.exe](https://github.com/GiorgioBurbanelli89/Calcpad-Octave/releases) (self-contained, no .NET required)

---

## ¿Qué hace distinto a Octave (y no a MATLAB)?

Calcpad Octave acepta las extensiones de sintaxis propias de GNU Octave. Verificado corriendo:

| Sintaxis Octave (falla en MATLAB estricto) | Soportada |
|---|---|
| Comentarios `#` y encabezados `##` | ✅ |
| Asignación compuesta `+= -= *= /=` | ✅ |
| Incremento/decremento `++x` `--x` (prefijo) y `x++` `x--` (postfijo) | ✅ |
| Bucle `do … until COND` (exclusivo de Octave) | ✅ |
| Terminadores `endfor` / `endif` / `endwhile` | ✅ |
| `!` y `!=` (alias de `~` y `~=`) | ✅ |
| Strings con comillas dobles y escapes (`"\n"`, `"\t"`) | ✅ |
| `printf` / `puts` / `fputs` / `fdisp` / `fflush` | ✅ |
| `rows(x)` / `columns(x)` | ✅ |
| Continuación de línea con `\` | ✅ |

Ejemplo que **solo** corre en Calcpad Octave (en Calcpad Lab da `Unexpected character '#'`):

```octave
# Cálculo en sintaxis Octave
x = 0;
x += 5;            # asignación compuesta
x++;               # postfijo
++x;               # prefijo
printf("x = %d\n", x);     # printf + escape \n  ->  x = 7

k = 0;
do                 # bucle do...until (no existe en MATLAB)
  k++;
until k >= 3
printf("k = %d\n", k);     # k = 3
```

> **Honestidad de alcance:** Calcpad Octave implementa la **sintaxis** distintiva de Octave sobre
> un motor propio con JIT + MKL (más rápido en bucles que el Octave interpretado, y con render
> tipo worksheet). **No** es un reemplazo completo de GNU Octave: este último es un intérprete
> maduro con miles de funciones, sparse real, clases y paquetes Forge. Pendientes conocidos:
> `unwind_protect` y `**` como alias de `^`.

---

## Por qué un programa aparte de Calcpad Lab

- **Calcpad Lab** → `.m` en **MATLAB estricto** (compatibilidad con MATLAB R2017a).
- **Calcpad Octave** → `.m` en **Octave**: el modo Octave es el comportamiento por defecto
  (se puede forzar MATLAB estricto con la variable de entorno `CALCPAD_OCTAVE=0` para comparar).

Ambos comparten el mismo motor (tokenizer + parser + evaluator + JIT + solver MKL/OpenBLAS/Eigen)
y el mismo render de Calcpad (texto + ecuaciones + gráficas inline + export PDF/DOCX).

---

## Instalación

1. Descargar **CalcpadOctave-Setup-1.0.0.exe** desde los
   [releases del repo](https://github.com/GiorgioBurbanelli89/Calcpad-Octave/releases).
2. Doble-click → aceptar UAC → seguir el wizard (acepta asociación `.m`).
3. Abrir cualquier `.m` (`Ctrl+O`) o crear uno nuevo (`Ctrl+N`); con **AutoRun** se ejecuta al guardar.

**No requiere .NET Desktop Runtime** — el runtime .NET 10 viaja dentro del installer (self-contained).

### CLI

```bash
CalcpadOctaveCli.exe mi_script.m salida.html    # genera HTML
CalcpadOctaveCli.exe mi_script.m salida.pdf      # genera PDF
```

---

## Build from source

Requiere **.NET 10 SDK**.

```bash
git clone https://github.com/GiorgioBurbanelli89/Calcpad-Octave.git
cd Calcpad-Octave
dotnet build Symbolic.Wpf/Symbolic.Wpf.csproj -c Release
dotnet build Symbolic.Cli/Symbolic.Cli.csproj -c Release
```

---

## Acknowledgments

- Fork de [Calcpad Lab](https://github.com/GiorgioBurbanelli89/Calcpad-Lab), a su vez sobre
  [Calcpad](https://github.com/Proektsoftbg/Calcpad) (Nedelcho Ganchovski, MIT) — mismo renderer.
- Sintaxis de referencia: [GNU Octave](https://octave.org/) (GPL) — Calcpad Octave es una
  reimplementación independiente de su sintaxis, no usa código de Octave.
- Intel MKL / OpenBLAS / Eigen 3 para el álgebra lineal nativa.

## License

MIT
