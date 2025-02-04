{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs             #-}
module Exercises where

import           Control.Applicative (liftA2)
{- ONE -}

-- | Let's introduce a new class, 'Countable', and some instances to match.
class Countable a where count :: a -> Int
instance Countable Int  where count   = id
instance Countable [a]  where count   = length
instance Countable Bool where count x = if x then 1 else 0

-- | a. Build a GADT, 'CountableList', that can hold a list of 'Countable'
-- things.

data CountableList where
  CountableNil :: CountableList
  CountableCons :: Countable a => a -> CountableList -> CountableList


-- | b. Write a function that takes the sum of all members of a 'CountableList'
-- once they have been 'count'ed.

countList :: CountableList -> Int
countList CountableNil         = 0
countList (CountableCons x xs) = count x + countList xs


-- | c. Write a function that removes all elements whose count is 0.

dropZero :: CountableList -> CountableList
dropZero CountableNil = CountableNil
dropZero (CountableCons x xs) = if count x == 0 then dropZero xs else CountableCons x (dropZero xs)


-- | d. Can we write a function that removes all the things in the list of type
-- 'Int'? If not, why not?

filterInts :: CountableList -> CountableList
filterInts = error "Cannot implement this because I know nothing about the type inside the CountableCount"


{- TWO -}

-- | a. Write a list that can take /any/ type, without any constraints.

data AnyList where
  ANil :: AnyList
  ACon :: a -> AnyList -> AnyList

-- | b. How many of the following functions can we implement for an 'AnyList'?

appendAnyList :: a -> AnyList -> AnyList
appendAnyList x ANil        = ACon x ANil
appendAnyList x (ACon y ys) = ACon x $ appendAnyList x ys

concatAnyList :: AnyList -> AnyList -> AnyList
concatAnyList ANil xs        = xs
concatAnyList xs ANil        = xs
concatAnyList xs (ACon y ys) = concatAnyList (appendAnyList y xs) ys


reverseAnyList :: AnyList -> AnyList
reverseAnyList ANil        = ANil
reverseAnyList (ACon x xs) = appendAnyList x (reverseAnyList xs)

-- Impossible to implement "properly", forall a . a -> Bool cannot be used here
filterAnyList :: (a -> Bool) -> AnyList -> AnyList
filterAnyList _ ANil = ANil
filterAnyList f (ACon x xs) = if True then ACon x (filterAnyList f xs) else filterAnyList f xs

lengthAnyList :: AnyList -> Int
lengthAnyList ANil        = 0
lengthAnyList (ACon _ xs) = 1 + lengthAnyList xs

-- Impossible to implement "properly" the monoid cannot be related with the existential *a*
foldAnyList :: Monoid m => AnyList -> m
foldAnyList = const mempty

isEmptyAnyList :: AnyList -> Bool
isEmptyAnyList ANil = True
isEmptyAnyList _    = False


-- Impossible
instance Show AnyList where
  show = error "What about me?"


{- THREE -}

-- | Consider the following GADT:

data TransformableTo output where
  TransformWith
    :: (input -> output)
    ->  input
    -> TransformableTo output

-- | ... and the following values of this GADT:

transformable1 :: TransformableTo String
transformable1 = TransformWith show 2.5

transformable2 :: TransformableTo String
transformable2 = TransformWith (uncurry (++)) ("Hello,", " world!")

-- | a. Which type variable is existential inside 'TransformableTo'? What is
-- the only thing we can do to it?

-- a. The existential type variable is `input` the only thing we can do with it is applying the function provided `input -> output`

-- | b. Could we write an 'Eq' instance for 'TransformableTo'? What would we be
-- able to check?

-- b. We can create an Eq instance checking the result of the transformation, for which we also have to set the `Eq` constrain

instance Eq out => Eq (TransformableTo out) where
  (TransformWith f x) == (TransformWith g y) = f x == g y


-- | c. Could we write a 'Functor' instance for 'TransformableTo'? If so, write
-- it. If not, why not?

instance Functor TransformableTo where
  fmap f (TransformWith g x) = TransformWith (f . g) x

{- FOUR -}

-- | Here's another GADT:

data EqPair where
  EqPair :: Eq a => a -> a -> EqPair

-- | a. There's one (maybe two) useful function to write for 'EqPair'; what is
-- it?

eq :: EqPair -> Bool
eq (EqPair a a') = a == a'

ne :: EqPair -> Bool
ne = not . eq

-- | b. How could we change the type so that @a@ is not existential? (Don't
-- overthink it!)

data EqPair' a where
  EqPair' :: Eq a => a -> a -> EqPair' a

-- | c. If we made the change that was suggested in (b), would we still need a
-- GADT? Or could we now represent our type as an ADT?

-- We could write this with {-# LANGUAGE DatatypeContexts #-}, edit: it seems it is included in recent versions of GHC
data Num a => EqPair'' a = EqPair'' a a



{- FIVE -}

-- | Perhaps a slightly less intuitive feature of GADTs is that we can set our
-- type parameters (in this case @a@) to different types depending on the
-- constructor.

data MysteryBox a where
  EmptyBox  ::                                MysteryBox ()
  IntBox    :: Int    -> MysteryBox ()     -> MysteryBox Int
  StringBox :: String -> MysteryBox Int    -> MysteryBox String
  BoolBox   :: Bool   -> MysteryBox String -> MysteryBox Bool

-- | When we pattern-match, the type-checker is clever enough to
-- restrict the branches we have to check to the ones that could produce
-- something of the given type.

getInt :: MysteryBox Int -> Int
getInt (IntBox int _) = int

-- | a. Implement the following function by returning a value directly from a
-- pattern-match:

getInt' :: MysteryBox String -> Int
getInt' (StringBox _ ((IntBox int _))) = int

-- | b. Write the following function. Again, don't overthink it!

countLayers :: MysteryBox a -> Int
countLayers EmptyBox          = 0
countLayers (IntBox _ box)    = 1 + countLayers box
countLayers (StringBox _ box) = 1 + countLayers box
countLayers (BoolBox _ box)   = 1 + countLayers box


-- | c. Try to implement a function that removes one layer of "Box". For
-- example, this should turn a BoolBox into a StringBox, and so on. What gets
-- in our way? What would its type be?

-- We know nothing about b, it's impossible to produce valid value. Remember, its forall b
removeLayer :: MysteryBox a -> Maybe (MysteryBox b)
removeLayer EmptyBox       = Nothing
-- removeLayer (IntBox _ box) = Just box


{- SIX -}

-- | We can even use our type parameters to keep track of the types inside an
-- 'HList'!  For example, this heterogeneous list contains no existentials:

data HList a where
  HNil  :: HList ()
  HCons :: head -> HList tail -> HList (head, tail)


exampleHList :: HList (String, (Int, (Bool, ())))
exampleHList = HCons "Tom" (HCons 25 (HCons True HNil))

-- | a. Write a 'head' function for this 'HList' type. This head function
-- should be /safe/: you can use the type signature to tell GHC that you won't
-- need to pattern-match on HNil, and therefore the return type shouldn't be
-- wrapped in a 'Maybe'!

headHL :: HList (a, b) -> a
headHL (HCons h _) = h

-- | b. Currently, the tuples are nested. Can you pattern-match on something of
-- type @HList (Int, String, Bool, ())@? Which constructor would work?

patternMatchMe :: HList (Int, String, Bool, ()) -> Int
-- patternMatchMe HNil = 42
-- patternMatchMe HCons h hl = ?
patternMatchMe = undefined

-- | c. Can you write a function that appends one 'HList' to the end of
-- another? What problems do you run into?

-- Don't know the type of the result
-- appendHL :: HList a -> HList b -> HList ?



{- SEVEN -}

-- | Here are two data types that may help:

data Empty
data Branch left centre right

-- | a. Using these, and the outline for 'HList' above, build a heterogeneous
-- /tree/. None of the variables should be existential.

data HTree a where
  EmptyTree :: HTree Empty
  BranchTree :: HTree a -> b -> HTree c -> HTree (Branch a b c)

-- | b. Implement a function that deletes the left subtree. The type should be
-- strong enough that GHC will do most of the work for you. Once you have it,
-- try breaking the implementation - does it type-check? If not, why not?

deleteLeft :: HTree (Branch a b c) -> HTree (Branch Empty b c)
deleteLeft (BranchTree _ c r) = BranchTree EmptyTree c r

-- | c. Implement 'Eq' for 'HTree's. Note that you might have to write more
-- than one to cover all possible HTrees. You might also need an extension or
-- two, so look out for something... flexible... in the error messages!
-- Recursion is your friend here - you shouldn't need to add a constraint to
-- the GADT!

instance Eq (HTree Empty) where
  _ == _   = True


instance (Eq (HTree a), Eq b, Eq (HTree c)) => Eq (HTree (Branch a b c)) where
  BranchTree tl1 c1 tr1 == BranchTree tl2 c2 tr2 = tl1 == tl2 && c1 == c2 && tr1 == tr2
  _ == _                   = False


{- EIGHT -}

-- | a. Implement the following GADT such that values of this type are lists of
-- values alternating between the two types. For example:
--
-- @
--   f :: AlternatingList Bool Int
--   f = ACons True (ACons 1 (ACons False (ACons 2 ANil)))
-- @

data AlternatingList a b where
  AltNil :: AlternatingList a b
  AltCons :: a -> AlternatingList b a  -> AlternatingList a b

-- | b. Implement the following functions.

getFirsts :: AlternatingList a b -> [a]
getFirsts AltNil           = []
getFirsts (AltCons a tail) = a: getSeconds tail

getSeconds :: AlternatingList a b -> [b]
getSeconds AltNil           = []
getSeconds (AltCons _ tail) = getFirsts tail

-- | c. One more for luck: write this one using the above two functions, and
-- then write it such that it only does a single pass over the list.

foldValues :: (Monoid a, Monoid b) => AlternatingList a b -> (a, b)
foldValues = ((,) . mconcat . getFirsts) <*> (mconcat . getSeconds)
foldValues' :: (Monoid a, Monoid b) => AlternatingList a b -> (a, b)
foldValues' xs = (mconcat $ getFirsts xs, mconcat $ getSeconds xs)

foldValues'' :: (Monoid a, Monoid b) => AlternatingList a b -> (a, b)
foldValues'' AltNil          = (mempty, mempty)
foldValues'' (AltCons a AltNil) = (a, mempty)
foldValues'' (AltCons a tail)   = (a <> a', b)
  where
    (b, a') = foldValues'' tail



{- NINE -}

-- | Here's the "classic" example of a GADT, in which we build a simple
-- expression language. Note that we use the type parameter to make sure that
-- our expression is well-formed.

data Expr a where
  Equals    :: Expr Int  -> Expr Int            -> Expr Bool
  Add       :: Expr Int  -> Expr Int            -> Expr Int
  If        :: Expr Bool -> Expr a   -> Expr a  -> Expr a
  IntValue  :: Int                              -> Expr Int
  BoolValue :: Bool                             -> Expr Bool

-- | a. Implement the following function and marvel at the typechecker:

eval :: Expr a -> a
eval = error "Implement me"

-- | b. Here's an "untyped" expression language. Implement a parser from this
-- into our well-typed language. Note that (until we cover higher-rank
-- polymorphism) we have to fix the return type. Why do you think this is?

data DirtyExpr
  = DirtyEquals    DirtyExpr DirtyExpr
  | DirtyAdd       DirtyExpr DirtyExpr
  | DirtyIf        DirtyExpr DirtyExpr DirtyExpr
  | DirtyIntValue  Int
  | DirtyBoolValue Bool

parse :: DirtyExpr -> Maybe (Expr Int)
parse = error "Implement me"

-- | c. Can we add functions to our 'Expr' language? If not, why not? What
-- other constructs would we need to add? Could we still avoid 'Maybe' in the
-- 'eval' function?





{- TEN -}

-- | Back in the glory days when I wrote JavaScript, I could make a composition
-- list like @pipe([f, g, h, i, j])@, and it would pass a value from the left
-- side of the list to the right. In Haskell, I can't do that, because the
-- functions all have to have the same type :(

-- | a. Fix that for me - write a list that allows me to hold any functions as
-- long as the input of one lines up with the output of the next.

data TypeAlignedList a b where
  -- ...

-- | b. Which types are existential?

-- | c. Write a function to append type-aligned lists. This is almost certainly
-- not as difficult as you'd initially think.

composeTALs :: TypeAlignedList b c -> TypeAlignedList a b -> TypeAlignedList a c
composeTALs = error "Implement me, and then celebrate!"

