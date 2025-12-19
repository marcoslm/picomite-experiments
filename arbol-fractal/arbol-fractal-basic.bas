' =========================================================
'  FRACTAL DEMO: THE WIND TREE
'  Recursive Calculation -> Batch Array Drawing
'  For Picomite HDMI/USB (MMBasic)
'  Version puramente en MMBasic. Requiere FW 6.01
'  by Marcos LM 2025
' =========================================================

OPTION EXPLICIT
OPTION DEFAULT INTEGER
MODE 5
MAP RESET

' Configuracion
CONST MAX_DEPTH = 10         ' Profundidad maxima del fractal
CONST MAX_LINES = 2048       ' 2^11 lineas maximo (seguridad)
CONST DEG2RAD = 0.0174533

' Arrays Graficos
DIM INTEGER t_x1(MAX_LINES), t_y1(MAX_LINES)
DIM INTEGER t_x2(MAX_LINES), t_y2(MAX_LINES)
DIM INTEGER t_col(MAX_LINES)

' Cache de Paleta
DIM INTEGER paleta(16) ' Usaremos profundidad 0-15 para colores

' Variables de Animacion
DIM FLOAT global_ang = -1.57079 ' Apuntando arriba (-PI/2)
DIM FLOAT wind_force
DIM FLOAT growth
DIM INTEGER line_count
DIM INTEGER max_growth_depth = 60

' Variables Temporales
DIM INTEGER t_start, t_math, t_draw
DIM INTEGER fps_count = 0, fps_val = 0, timer_sec = TIMER
DIM INTEGER cx = MM.HRES \ 2
DIM INTEGER cy = MM.VRES

' Creamos paleta
MAP(0) = RGB(BLACK) ' Fondo seguro
MAP SET
' Tronco (Marron oscuro a claro)
paleta(0) = RGB(60, 40, 10)
paleta(1) = RGB(80, 50, 20)
paleta(2) = RGB(100, 70, 30)
paleta(3) = RGB(120, 90, 40)
' Hojas (Verde oscuro a brillante)
paleta(4) = RGB(0, 100, 0)
paleta(5) = RGB(0, 140, 0)
paleta(6) = RGB(20, 180, 20)
paleta(7) = RGB(40, 220, 40)
paleta(8) = RGB(100, 255, 100)
paleta(9) = RGB(120, 255, 120)  ' Puntas brillantes
paleta(10) = RGB(255, 180, 200) ' Flores (opcional)


CLS
FRAMEBUFFER CREATE
FRAMEBUFFER WRITE F

' =========================================================
'  BUCLE PRINCIPAL
' =========================================================
DO
  CLS
 
  ' Viento: Onda sinusoidal compuesta
  wind_force = SIN(TIMER / 500.0) * 0.1 + SIN(TIMER / 150.0) * 0.05
  
  ' Crecimiento: Aumenta el tamanyo hasta el limite
  IF growth < max_growth_depth THEN 
     growth = growth + 0.2
  ENDIF
  
  line_count = 0
  
  ' Calculo del fractal.
  ' Parametros: X, Y, Longitud, Angulo, Profundidad Actual
  TreeCalc(cx, cy, growth, global_ang, 0)
  
  ' Dibujamos todo el array. Las lineas no usadas (0,0,0,0) son puntos invisibles.
  LINE t_x1(), t_y1(), t_x2(), t_y2(), 1, t_col()
  FRAMEBUFFER COPY F,N
  
LOOP

' =========================================================
'  Calculo del fractal (recursiva)
'  No dibujamos, solo llenamos arrays
' =========================================================
SUB TreeCalc(x AS INTEGER, y AS INTEGER, leng AS FLOAT, ang AS FLOAT, depth AS INTEGER)
  
  ' Calcular punto final de la rama
  LOCAL INTEGER nx, ny
  nx = x + COS(ang) * leng
  ny = y + SIN(ang) * leng
  
  ' Guardar en Arrays (Batching)
  t_x1(line_count) = x
  t_y1(line_count) = y
  t_x2(line_count) = nx
  t_y2(line_count) = ny
  
  ' Color basado en profundidad
  IF depth > 10 THEN t_col(line_count) = paleta(10) ELSE t_col(line_count) = paleta(depth)
  
  INC line_count
  
  ' Condicion de parada y recursion
  IF depth < MAX_DEPTH AND line_count < MAX_LINES THEN
    
    ' Reducir longitud para la siguiente rama
    LOCAL FLOAT new_len = leng * 0.72
    
    ' Variacion del angulo basada en el viento y profundidad
    ' Las ramas se abren mas o menos segun el viento
    LOCAL FLOAT spread = 0.4 + (wind_force * 0.5) 
    
    ' Rama Izquierda
    TreeCalc(nx, ny, new_len, ang - spread + (wind_force * 0.1 * depth), depth + 1)
    
    ' Rama Derecha
    TreeCalc(nx, ny, new_len, ang + spread + (wind_force * 0.1 * depth), depth + 1)
    
  ENDIF
  
END SUB
