' ---------------------------------------------------------
'  Animacion Curvas de Rose con Starfield de fondo
'  por Marcos LM 2025
' ---------------------------------------------------------

OPTION EXPLICIT
OPTION DEFAULT INTEGER
MODE 5 

' Configuracion
CONST MAX_SEGS = 200
const MAX_SEGS_MINUS = MAX_SEGS - 1
CONST NUM_STARS = 100
CONST FOV_INT = 160
CONST SHOW_FPS = 0
CONST MOD_FILE = "musica.mod"

' Arrays Graficos
DIM INTEGER r_x1(MAX_SEGS), r_y1(MAX_SEGS)
DIM INTEGER r_x2(MAX_SEGS), r_y2(MAX_SEGS)
DIM INTEGER r_col(MAX_SEGS)
DIM INTEGER s_x(NUM_STARS), s_y(NUM_STARS)

' Arrays Fisica
DIM FLOAT star_x(NUM_STARS), star_y(NUM_STARS), star_z(NUM_STARS)

' Vectores y tablas
DIM FLOAT BaseCos(MAX_SEGS), BaseSin(MAX_SEGS)
DIM FLOAT BaseAng(MAX_SEGS)
DIM INTEGER PalCache(512) ' Doble buffer para la paleta
DIM FLOAT InvZ(550)       ' Tabla inversa Z

' Variables
DIM INTEGER cx = MM.HRES \ 2
DIM INTEGER cy = MM.VRES \ 2
DIM INTEGER scale = cy - 10
DIM FLOAT n = 2.0, d = 29.0
DIM FLOAT n_step = 0.0005, d_step = 0.002
DIM FLOAT k, r_geo, d_rad
DIM FLOAT deg2rad = 0.0174533
DIM FLOAT z_val, projection_factor

' Temporales
DIM INTEGER i, x_curr, y_curr, x_next, y_next
DIM INTEGER col_offset = 0
DIM INTEGER r_idx, g_idx, b_idx, rgb_val
DIM FLOAT rads
DIM INTEGER fps_val, fps_count, timer_sec
DIM INTEGER c_off

' Configurar Paleta
FOR i = 0 TO 255
  ' Calculamos el color arcoíris normal
  rads = (i / 255.0) * 6.283
  r_idx = 127 + 127 * SIN(rads)
  g_idx = 127 + 127 * SIN(rads + 2.09)
  b_idx = 127 + 127 * SIN(rads + 4.18)
  rgb_val = RGB(r_idx, g_idx, b_idx)
  
  IF i = 0 THEN
     MAP(0) = RGB(BLACK) ' fondo negro
  ELSE
     MAP(i) = rgb_val
  ENDIF

  ' Cache de paleta en memoria
  PalCache(i) = rgb_val
  PalCache(i + 256) = rgb_val ' Espejo
NEXT i
MAP SET

' Vectores Base
d_rad = d * deg2rad
FOR i = 0 TO MAX_SEGS
  k = i * d_rad
  BaseAng(i) = k
  BaseCos(i) = COS(k)
  BaseSin(i) = SIN(k)
NEXT i

' Tabla InvZ
InvZ(0) = 1.0
FOR i = 1 TO 550
    InvZ(i) = FOV_INT / i
NEXT i

' Estrellas
FOR i = 0 TO NUM_STARS
  star_x(i) = (RND * 2000) - 1000 : star_y(i) = (RND * 2000) - 1000 : star_z(i) = RND * 500
NEXT i

CLS
FRAMEBUFFER CREATE
FRAMEBUFFER WRITE F

play modfile MOD_FILE ' Musiquita

'  BUCLE PRINCIPAL
DO
  CLS
  
  ' Estrellas
  FOR i = 0 TO NUM_STARS
    z_val = star_z(i) - 15.0
    IF z_val <= 10.0 THEN 
       star_z(i) = 500.0 : star_x(i) = (RND * 2000) - 1000 : star_y(i) = (RND * 2000) - 1000
       s_x(i) = -10 : s_y(i) = -10 
    ELSE
       star_z(i) = z_val
       projection_factor = InvZ(z_val \ 1) 
       s_x(i) = cx + star_x(i) * projection_factor
       s_y(i) = cy + star_y(i) * projection_factor
    ENDIF
  NEXT i

  ' Curvas
  x_curr = cx : y_curr = cy
  c_off = col_offset 
  
  FOR i = 0 TO MAX_SEGS_MINUS
    r_geo = SIN(n * BaseAng(i+1)) * scale
    x_next = cx + r_geo * BaseCos(i+1)
    y_next = cy + r_geo * BaseSin(i+1)
    
    r_x1(i) = x_curr : r_y1(i) = y_curr
    r_x2(i) = x_next : r_y2(i) = y_next
    r_col(i) = PalCache(c_off + i)
    
    x_curr = x_next : y_curr = y_next
  NEXT i

  PIXEL s_x(), s_y()
  LINE r_x1(), r_y1(), r_x2(), r_y2(), 1, r_col()
  
  if SHOW_FPS then TEXT 0, 0, str$(fps_val)

  FRAMEBUFFER COPY F,N
  
  if SHOW_FPS then 
    INC fps_count
    IF TIMER - timer_sec >= 1000 THEN
      fps_val = fps_count : fps_count = 0 : timer_sec = TIMER
    ENDIF
  end if
  
  INC n, n_step
  IF n > 9.0 OR n < 2.0 THEN n_step = -n_step
  INC d, d_step
  
  INC col_offset, 2
  IF col_offset > 255 THEN col_offset = 0
LOOP
