module Exercises where

class PopQuiz a

-- | Which of the following instances require 'FlexibleInstances'? Don't cheat
-- :D This is a tricky one, but look out for nested concrete types!

instance PopQuiz Bool
-- instance PopQuiz [Bool] DO (not a type variable)
instance PopQuiz [a]
instance PopQuiz (a, b) --  DON'T (,) a b -> different type variables
-- instance PopQuiz [(a, b)] DO ((a,b) is a type)
instance PopQuiz (IO a)

newtype RIO  r a = RIO (r -> IO a) -- Remember, this is a /new type/.
type    RIO' r a =      r -> IO a

-- instance PopQuiz (RIO Int a) -- DO, Int is not a type variable
instance PopQuiz (RIO r a)
-- instance PopQuiz (RIO' r a) -- is the same as `(->) r (IO a)`, the second argument is not a type variable
-- instance PopQuiz (r -> IO a) -- same as above
-- instance PopQuiz (a -> b) -- We can write (a -> b) as ((->) a b).
-- instance PopQuiz (a -> b -> c) -- (a -> b) -> c DO, we have a type constructor here
instance PopQuiz (a, b, c)
-- instance PopQuiz (a, (b, c)) (,) a ((,) b c) DO, the second argument of the tuple is is not a type variable
instance PopQuiz ()
-- instance PopQuiz (a, b, c, a) -- DO, a is present twice

data Pair  a = Pair  a  a
type Pair' a =      (a, a)

-- instance PopQuiz (a, a) -- DO, is `(,) a a` a is not distinct (present twice)
instance PopQuiz (Pair a)
-- instance PopQuiz (Pair' a) -- same as the first one
