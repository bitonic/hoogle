
module Hoogle.Search.All where

import Data.Maybe
import Data.List

import Hoogle.DataBase.All
import Hoogle.Query.All
import Hoogle.Common.All
import Hoogle.TypeSig.All


-- return all the results
searchAll :: DataBase -> Query -> IO [Result]
searchAll database query = getResults database query


-- should be possible to fast-path certain searches, currently not done
searchRange :: DataBase -> Query -> Int -> Int -> IO [Result]
searchRange database query from to = do
    res <- getResults database query
    return $ take to $ drop from res


getResults :: DataBase -> Query -> IO [Result]
getResults database query | not (null $ names query) = performTextSearch database (head $ names query)
                          | isJust (typeSig query) = performTypeSearch database (fromJust $ typeSig query)
        

performTextSearch :: DataBase -> String -> IO [Result]
performTextSearch database query = do
        res <- searchName database query
        res <- return $ map head $ groupBy eqItemId $ sortBy cmpItemId res
        res <- loadResultsItem database res
        res <- loadResultsModule database res
        return $ sortBy priority $ map fixupTextMatch res
    where
        cmpItemId x y = getItemId x `compare` getItemId y
        eqItemId x y = getItemId x == getItemId y
        getItemId = fromJust . itemId . itemResult

        nquery = length query
        fixupTextMatch (Result (Just txt) item) = Result (Just $ TextMatch loc (nname-nquery) badCase) item
            where
                loc = textLoc txt
                name = fromJust $ itemName item
                nname = length name
                badCase = length $ filter id $ zipWith (/=) query (drop loc name)

        priority x y = getStatus x `compare` getStatus y
        getStatus (Result (Just txt) item) = (textElse txt, textCase txt, fromJust (itemName item))


performTypeSearch :: DataBase -> TypeSig -> IO [Result]
performTypeSearch database query = do
        res <- searchType database query
        error $ show res
