con colMeta = fn (db :: Type, widget :: Type) => { 
  Nam : string,
  Show : db -> xbody,
  Widget : nm :: Name -> transaction (xml form [] [nm = widget]),
  Parse : widget -> db,
  Inject : sql_injectable db }

con colsMeta = fn cols => $(map colMeta cols)

fun default [t] (sh : show t) (rd : read t) (inj : sql_injectable t)
  name : colMeta (t, string) = {
    Nam = name,
    Show = txt,
    Widget = fn [nm :: Name] => return <xml><textbox{nm}/></xml>,
    Parse = readError,
    Inject = _ }

val int = default
val float = default
val string = default

fun bool name = {
  Nam = name,
  Show = txt,
  Widget = fn [nm :: Name] => return <xml><checkbox{nm}/></xml>,
  Parse = fn x => x,
  Inject = _ }

functor Make( M : 
sig
  con cols :: {(Type * Type)}
  constraint [Id] ~ cols
  val fl : folder cols
  table tab : ([Id = int] ++ map fst cols)
  val title : string
  val cols : colsMeta cols
end ) = 
struct
  val tab = M.tab

  sequence seq

  fun list () =
    rows <- queryX 
      ( SELECT * FROM tab AS T)
      ( fn (fs : {T : $([Id = int] ++ map fst M.cols)}) => 
        <xml>
          <tr>
            <td>{[fs.T.Id]}</td>
            { @mapX2 
              [fst] 
              [colMeta] 
              [tr]
              ( fn [nm :: Name] [t ::_] [rest ::_] [[nm] ~ rest] v col => 
                <xml>
                  <td>{col.Show v}</td>
                </xml> )
              M.fl 
              (fs.T -- #Id) 
              M.cols }
          </tr>
        </xml> );
      return <xml>
        <table border={1}>
          <tr>
            <th>ID</th>
            { @mapX 
              [ colMeta ] 
              [ tr ]
              ( fn [nm :: Name] [t ::_] [rest ::_] [[nm] ~ rest] col => 
                <xml>
                  <th>{cdata col.Nam}</th>
                </xml> )
              M.fl 
              M.cols }
          </tr>
          {rows}
        </table>

        <br/><hr/><br/>

        <form>
          { @foldR 
            [ colMeta ] 
            [ fn cols => transaction (xml form [] (map snd cols)) ]
            ( fn [nm :: Name] [t ::_] [rest ::_] [[nm] ~ rest] (col : colMeta t) acc => 
              col_widget_nm <- col.Widget [nm] ;
              return 
              <xml>
                <li> {cdata col.Nam}: {col_widget_nm}</li>
                {useMore acc}
              </xml> )
            (return <xml/>)
            M.fl 
            M.cols }
          <submit action={create}/>
        </form>
      </xml>

  and create (inputs : $(map snd M.cols)) =
    id <- nextval seq;
    dml (insert tab
      ( @foldR2 
        [snd] 
        [colMeta]
        [ fn cols => $(map (fn t => sql_exp [] [] [] t.1) cols) ]
        ( fn [nm :: Name] [t ::_] [rest ::_] [[nm] ~ rest] =>
          fn input col acc => acc ++ {nm = @sql_inject col.Inject (col.Parse input)} )
        {} 
        M.fl 
        inputs 
        M.cols ++ { Id = ( SQL {[id]} ) } ) );
    ls <- list ();
    return <xml><body>
      <p>Inserted with ID {[id]}.</p>
        {ls}
      </body></xml>

  and main () =
    ls <- list ();
    return <xml>
      <head>
        <title>{cdata M.title}</title>
      </head>
      <body>
        <h1>{cdata M.title}</h1>
        {ls}
      </body>
    </xml>
  end
