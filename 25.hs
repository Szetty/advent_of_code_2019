{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE NamedFieldPuns    #-}
{-# LANGUAGE OverloadedStrings #-}

import           Control.Monad.State
import           Data.Array
import           Data.Char
import           Data.Either
import           Data.Int
import qualified Data.List                  as List
import           Data.Maybe
import           Data.Text
import           Data.Void
import           Debug.Trace
import           Replace.Megaparsec
import           Text.Megaparsec            (Parsec, parseMaybe)
import           Text.Megaparsec.Char.Lexer

data IntcodeComputer =
  IntcodeComputer
    { i             :: Int
    , relative_base :: Int
    , halted        :: Bool
    , codes         :: Array Int Int64
    }
  deriving (Show)

initializeIC :: Text -> IntcodeComputer
initializeIC program =
  IntcodeComputer {i = 0, relative_base = 0, halted = False, codes = codes}
  where
    codes = buildCodes $ splitOn "," program
    buildCodes l = toArray $ extend (toInt <$> l)
    toArray l = array (0, List.length l - 1) $ enumerate l
    extend l = l ++ List.replicate (10 * List.length l) 0
    toInt code = read (unpack code) :: Int64
    enumerate = List.zip [0 ..]

extractOpcodeAndParameterModes :: Int64 -> (Int, [Int])
extractOpcodeAndParameterModes instruction =
  (fromIntegral opcode, parameterModes)
  where
    opcode = instruction `mod` 100
    parameterModes =
      [ fromIntegral (instruction `div` 100) `mod` 10
      , fromIntegral (instruction `div` 1000) `mod` 10
      , fromIntegral (instruction `div` 10000) `mod` 10
      ]

operand :: IntcodeComputer -> [Int] -> Int -> Int64
operand IntcodeComputer {codes, i, relative_base} parameterModes offset = result
  where
    result =
      case parameterModes !! (offset - 1) of
        0 -> codes ! fromIntegral (codes ! (i + offset))
        1 -> codes ! (i + offset)
        2 -> codes ! (relative_base + fromIntegral (codes ! (i + offset)))

store :: IntcodeComputer -> [Int] -> Int -> Int64 -> IntcodeComputer
store IntcodeComputer {codes, i, relative_base, halted} parameterModes offset value =
  computer
  where
    computer = IntcodeComputer { codes = new_codes, i = i, relative_base = relative_base, halted = halted}
    new_codes =
      case parameterModes !! (offset - 1) of
        0 -> codes // [(fromIntegral (codes ! (i + offset)), value)]
        2 -> codes // [(relative_base + fromIntegral (codes ! (i + offset)), value)]

runProgram :: [Int64] -> State IntcodeComputer [Int64]
runProgram inputs = doRunProgram inputs []

doRunProgram :: [Int64] -> [Int64] -> State IntcodeComputer [Int64]
doRunProgram inputs outputs = do
  computer <- get
  let IntcodeComputer {codes, i, relative_base, halted} = computer
  if halted
    then return outputs
    else do
      let (opcode, parameterModes) = extractOpcodeAndParameterModes $ codes ! i
      let o = operand computer parameterModes
      let s = store computer parameterModes
      case opcode of
        1 -> u_i (i + 4) (s 3 (o 1 + o 2)) >> loop
        2 -> u_i (i + 4) (s 3 (o 1 * o 2)) >> loop
        3 ->
          case inputs of
            [] -> return outputs
            (input:inputs) ->
              u_i (i + 2) (s 1 input) >> doRunProgram inputs outputs
        4 -> u_i (i + 2) computer >> doRunProgram inputs (outputs ++ [o 1])
        5 -> u_i (if o 1 /= 0 then fromIntegral (o 2) else i + 3) computer >> loop
        6 -> u_i (if o 1 == 0 then fromIntegral (o 2) else i + 3) computer >> loop
        7 -> u_i (i + 4) (s 3 (if o 1 < o 2 then 1 else 0)) >> loop
        8 -> u_i (i + 4) (s 3 (if o 1 == o 2 then 1 else 0)) >> loop
        9 -> u_i (i + 2) (computer {relative_base = relative_base + fromIntegral (o 1)}) >> loop
        99 -> put computer {halted = True} >> loop
  where
    u_i i comp = put (comp {i = i})
    loop = doRunProgram inputs outputs

processCommand :: String -> [Int64]
processCommand command =
  case List.take 1 command of
    "n" -> fmap (fromIntegral . ord) "north\n"
    "s" -> fmap (fromIntegral . ord) "south\n"
    "w" -> fmap (fromIntegral . ord) "west\n"
    "e" -> fmap (fromIntegral . ord) "east\n"
    "t" -> fmap (fromIntegral . ord) ("take" ++ List.drop 1 command ++ "\n")
    "d" -> fmap (fromIntegral . ord) ("drop" ++ List.drop 1 command ++ "\n")
    "i" -> fmap (fromIntegral . ord) "inv\n"
    "q" -> []

processOutput :: IntcodeComputer -> String -> IO (Maybe Int64)
processOutput computer output
  | output == "" = return Nothing
  | List.isSubsequenceOf "Analysis complete! You may proceed." output =
    putStrLn output >>
    (return . Just . List.head . rights . fromJust $
     parseMaybe (sepCap (decimal :: Parsec Void String Int64)) output)
  | otherwise = do
    putStrLn output
    putStrLn
      "Commands: (n)orth, (s)outh, (w)est, (e)ast, (t)ake <item>, (d)rop <item>, (i)nv, (q)uit\n"
    c <- getLine
    case processCommand c of
      []      -> return (Just 0)
      command -> loopInteractive computer command

loopInteractive :: IntcodeComputer -> [Int64] -> IO (Maybe Int64)
loopInteractive computer command = do
  let (output, computer1) = runState (runProgram command) computer
  processOutput computer1 (chr . fromIntegral <$> output)

solveInteractive :: String -> IO ()
solveInteractive program = do
  output <- loopInteractive (initializeIC . pack $ program) []
  case output of
    Nothing -> do
      putStrLn "\nRestarting game\n"
      solveInteractive program
    Just i -> print i

main = do
  program <- readFile "inputs/25"
  solveInteractive program
