{-# LANGUAGE CPP #-}
module Recipe.Cabal(
    Cabal(..), readCabal
    ) where

import Distribution.Compiler
import Distribution.Package
import Distribution.PackageDescription
import Distribution.PackageDescription.Configuration
import Distribution.PackageDescription.Parse
import Distribution.System
import Distribution.Text
import Distribution.Verbosity
import Distribution.Version
import Language.Haskell.Extension (Language(..))
import Recipe.Haddock


ghcVersion = [7,8,3]

data Cabal = Cabal
    {cabalName :: String
    ,cabalVersion :: String
    ,cabalDescription :: [String]
    ,cabalDepends :: [String]
    } deriving Show


readCabal :: FilePath -> IO Cabal
readCabal file = do
    pkg <- readPackageDescription silent file
    let plat = Platform I386 Linux
        compid = CompilerId GHC (Version ghcVersion [])
#if __GLASGOW_HASKELL__ < 710
        comp = compid
#else
        comp = CompilerInfo
                 { compilerInfoId = compid
                 , compilerInfoAbiTag = NoAbiTag
                 , compilerInfoCompat = Nothing
                 , compilerInfoLanguages = Just [Haskell98, Haskell2010]
                   -- It's too much of a pain to get all the extensions,
                   -- things work anyway.  See 'getExtensions' in
                   -- 'Distribution.Simple.GHC.Internal'.
                 , compilerInfoExtensions = Nothing
                 }
#endif
    pkg <- return $ case finalizePackageDescription [] (const True) plat comp [] pkg of
        Left _ -> flattenPackageDescription pkg
        Right (pkg,_) -> pkg
    return $ Cabal
        (display $ pkgName $ package pkg)
        (display $ pkgVersion $ package pkg)
        (haddockToHTML $ description pkg)
        [display x | Just l <- [library pkg], Dependency x _ <- targetBuildDepends $ libBuildInfo l]
