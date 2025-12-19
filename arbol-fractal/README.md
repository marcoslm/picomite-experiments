# arbol-fractal para Picomite HDMI/USB RP2350A

![Screenshot](screenshot.png)

Animación de un árbol fractal creciendo en pantalla.

Este repositorio contiene dos demos/experimentos para la Picomite HDMI/USB RP2350A (quizás también funcionen en Picomite VGA, aunque la paleta de colores será diferente).

- **arbol-fractal-basic.bas**: versión simple y puramente en MMBasic, todos los cálculos se hacen en Basic.
- **arbol-fractal-csub.bas**: versión optimizada que usa una rutina en código máquina (generada a partir de `treecalc.c`) para los cálculos intensivos, logrando una animación más fluida.

Las físicas se hicieron con asistencia de IA.
