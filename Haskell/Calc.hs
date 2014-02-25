import Foreign
import Foreign.C

foreign export ccall "calcSpeed" calcSpeed :: CInt -> CFloat -> CFloat
foreign export ccall "calcTacho" calcTacho :: CInt -> CFloat -> CFloat

gs = [3.42, 2.14, 1.45, 1.03, 0.81]
f = 4.07
c = 55.0
l = 205.0
d = 16.0
e = 0.057
unit = 3.5

calcSpeed :: Int -> Float -> Float
calcSpeed i r
  | i >= 0 && i < 5 = let v = pi * (2 * c * l / 100000 + 0.0254 * d) * r / (60 * f * gs !! i) * unit
                      in v * (1 + e)
  | otherwise = 0.0

calcTacho :: Int -> Float -> Float
calcTacho i v
  | i >= 0 && i < 5 = (60 * f * gs !! i) * v / (1 + e) / unit / pi / (2 * c * l / 100000 + 0.0254 * d)
  | otherwise = 0.0

main :: IO ()
main = return ()
