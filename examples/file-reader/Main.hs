{-# LANGUAGE CPP #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Main where

import Control.Concurrent.MVar
import Miso
import Miso.String

#ifdef GHCJS_NEW
import GHC.JS.Foreign.Callback
#endif
import GHCJS.Types
#ifdef GHCJS_OLD
import GHCJS.Foreign.Callback
#endif

-- | Model
data Model = Model
    { info :: MisoString
    }
    deriving (Eq, Show)

-- | Action
data Action
    = ReadFile
    | NoOp
    | SetContent MisoString
    deriving (Show, Eq)

-- | Main entry point
main :: IO ()
main = run $ do
    startApp
        App
            { model = Model ""
            , initialAction = Nothing
            , ..
            }
  where
    mountPoint = Nothing
    update = updateModel
    events = defaultEvents
    subs = []
    view = viewModel
    logLevel = Off

-- | Update your model
updateModel :: Action -> Model -> Effect Action Model
updateModel ReadFile m =
    m <# do
        fileReaderInput <- getElementById "fileReader"
        file <- getFile fileReaderInput
        reader <- newReader
        mvar <- newEmptyMVar
        setOnLoad reader =<< do
            asyncCallback $ do
                r <- getResult reader
                putMVar mvar r
        readText reader file
        SetContent <$> readMVar mvar
updateModel (SetContent c) m = noEff m{info = c}
updateModel NoOp m = noEff m

-- | View function, with routing
viewModel :: Model -> View Action
viewModel Model{..} = view
  where
    view =
        div_
            []
            [ "FileReader API example"
            , input_
                [ id_ "fileReader"
                , type_ "file"
                , onChange (const ReadFile)
                ]
            , div_ [] [text info]
            ]

#ifdef GHCJS_NEW
foreign import javascript unsafe "(() => { return new FileReader(); })"
  newReader :: IO JSVal

foreign import javascript unsafe "((x) => { return x.files[0]; })"
  getFile :: JSVal -> IO JSVal

foreign import javascript unsafe "((x, y) => { x.onload = y; })"
  setOnLoad :: JSVal -> Callback (IO ()) -> IO ()

foreign import javascript unsafe "((x) => { return x.result; })"
  getResult :: JSVal -> IO MisoString

foreign import javascript unsafe "((x, y) => { x.readAsText(y); })"
  readText :: JSVal -> JSVal -> IO ()
#endif

#ifdef GHCJS_OLD
foreign import javascript unsafe "$r = new FileReader();"
  newReader :: IO JSVal

foreign import javascript unsafe "$r = $1.files[0];"
  getFile :: JSVal -> IO JSVal

foreign import javascript unsafe "$1.onload = $2;"
  setOnLoad :: JSVal -> Callback (IO ()) -> IO ()

foreign import javascript unsafe "$r = $1.result;"
  getResult :: JSVal -> IO MisoString

foreign import javascript unsafe "$1.readAsText($2);"
  readText :: JSVal -> JSVal -> IO ()
#endif
