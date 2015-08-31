**Modifying the Crud1 demo: Attempting to change the result type of `Widget` from `xml` to `transaction xml` - Does not compile yet!**


**Goal:**

I am attempting to do a minimal modification of the Crud1 demo, to change the result type of the `Widget` field in the constructor `colMeta` from `xml` to `transaction xml`:

  OLD: http://www.impredicative.com/ur/demo/crud1.html

  NEW: https://github.com/StefanScott/UrWeb-crudWidgetTxn1

  DIFF: https://github.com/StefanScott/UrWeb-crudWidgetTxn1/commit/77edc38ce23d44e7e00910e433feb9946a7ad1d9

- The `Widget` field in (my simplified, working version of) the Crud1 demo originally declares a function having result type of `xml`:

    `Widget : nm :: Name -> xml form [] [nm = widget]`

- The `Widget` field in my new (non-working) version UrWeb-crudWidgetTxn1 has been changed, so that it now declares a function having result type `transaction xml`:

    `Widget : nm :: Name -> transaction (xml form [] [nm = widget])`


**GitHub commit allowing line-by-line comparison:**

My (minimal) changes are highlighted in a specially created GitHub repo having only 2 commits:

(1) The *first* commit is (a simplified version of) the Crud1 demo (it only does SELECT and INSERT - no DELETE or UPDATE). Being based directly on Crud1, it compiles and runs correctly.

(2) The *second* commit merely changes the result type of `Widget` from `xml` to `transaction xml` - in three places:

  https://github.com/StefanScott/UrWeb-crudWidgetTxn1/commit/77edc38ce23d44e7e00910e433feb9946a7ad1d9

(a) the *declaration* of the function in field `Widget` of constructor `colMeta`

(b) the *invocation* of the function in field `Widget`

(c) the declared *types* of the higher-order functional arguments to `@foldR`

Apparently something is wrong with (b) and/or (c) in UrWeb-crudWidgetTxn1.


**Errors:**

My modified version of Crud1, using *meta-programming*, does not compile. 

I suspect this is because something is wrong with the types of the arguments in the call to `@foldR`.

My new version gives "Unification failure" compile errors ("Have transaction, Need xml" and "Have xml, Need transaction"). The complete compile error message is here:

  https://github.com/StefanScott/UrWeb-crudWidgetTxn1/blob/master/err.001.txt


The portions below underlined using `(* ^^^^ *)` are probably incorrect:

  https://github.com/StefanScott/UrWeb-crudWidgetTxn1/blob/master/crudWidgetTxn.ur#L82-L98
```
  <form>
    { @foldR 
      [ colMeta ] 
      [ fn cols => transaction (xml form [] (map snd cols)) ]
                (* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ *)
      ( fn [nm :: Name] [t ::_] [rest ::_] [[nm] ~ rest] (col : colMeta t) acc => 
        col_widget_nm <- col.Widget [nm] ;
     (* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ *)          
        return 
        <xml>
          <li> {cdata col.Nam}: {col_widget_nm}</li>
                               (* ^^^^^^^^^^^^^ *)          
          {useMore acc}
        </xml> )
      (return <xml/>)
      M.fl 
      M.cols }
    <submit action={create}/>
  </form>
```

**Question (1):**

Can anyone see what might be wrong with the types in the call to `@foldR` above?

**Question (2):**

Does this overall strategy make sense - minimally modifying Crud1 to change the result type of the `Widget` function from `xml` to `transaction xml`?

I adopted this strategy because:

(a) If I want `Widget` to return a `<select>` tag containing `<option>` tags, this requires doing a "transaction" to read the database - so it seems that it will be necessary for `Widget` to return a "transactional" type.

(b) The working, non-meta-programming example [UrWeb-colorSize](https://github.com/StefanScott/UrWeb-colorSize) demonstrates that it is indeed possible to insert something of type `transaction xml` inside something of type `transaction form`.

(c) Due to the complexity of the higher-order types in the Crud1 demo, I would like to perform a "surgical" or "extremely limited" extension - changing as *little* of Crud1 as possible, so as to be able to leverage most of the existing, correct code (which involves several higher-order functions that would be very difficult for me to correctly define "from scratch"!)

Thanks for any help!

---

**Motivation:**

I believe that changing the result type of the `Widget` function is necessary for a related project: defining data-bound `<select>` widgets for foreign-key fields.

This requires doing a "read" transaction on the database - eg, running `queryX1` to create `<option>` tags in a `<select>` tag, corresponding to records in the "parent" table of the foreign-key field.

For *non-foreign* fields of types `bool`, `int`, `float` and `string`, the Crud1 demo already includes examples of definitions of functions for the `Widget` field which return a `<textbox>` and a `<checkbox>`.

For cases where the `Widget`'s column is a *foreign-key* column, I want to define a function returning a `<select>` tag containing `<option>` tags. This will of course require performing a "read" transaction on the database - in order to query the records of the "parent" table of the foreign-key column.

I therefore believe that the `<select>` widget, composed of `<option>` tags, *must* be a transactional type, due to the need to read the database to select the records used to build the actual widget.

So it seems that a good approach would be to modify the Crud1 demo so that the function in the `Widget` field has a result type of `transaction xml` instead of `xml`.


**Comparison with a working, *non-meta-programming* example:**

As a test, I have also developed a working example *without* using meta-programming. 

It lets the user edit a table (Thing) having 2 foreign-key columns (Color and Size). 

There is a live demo online, plus a GitHub repo:

  http://personalenglish.org/ColorSize/main

  https://github.com/StefanScott/UrWeb-colorSize


**Contribution of the working, *non-meta-programming* example:**

Previously, I had made a conjecture that the error in the present non-working, meta-programming example might have been due to attempting to put something of type `transaction xml` inside a `<form>`.

However, the *non-meta-programming* example above (ColorSize) disproves this conjecture, because it *does* successfully insert something (`color_options_xml`) of type `transaction xml` into a `<form>` tag, here:

---

https://github.com/StefanScott/UrWeb-colorSize/blob/master/colorSize.ur#L378-L381
```
  color_options_xml <- 
(*^^^^^^^^^^^^^^^^^*)
    queryX1 
      ( SELECT * FROM color ORDER BY color.Nam)
      ( fn r => <xml> <option> {[r.Nam]} </option> </xml> )
  ;
```

https://github.com/StefanScott/UrWeb-colorSize/blob/master/colorSize.ur#L399-L415
```
  <form>
    <h2>Add a Thing:</h2>
    <table>
      <tr> <th>Name:</th>  <td> <textbox {#Nam} /> </td> </tr>
      <tr> <th>Color:</th> <td> <select  {#ColorNam} >

        {color_options_xml}
       (*^^^^^^^^^^^^^^^^^*)
      </select> </td> </tr>
      (* ... *)
      <tr> <th/> <td> <submit action={create} value="Add Thing !"/> </td> </tr>
    </table>
  </form>
```
---

So the (working) *non-meta-programming* example [UrWeb-colorSize](https://github.com/StefanScott/UrWeb-colorSize) shows that it is indeed possible to insert something of type `transaction xml` into a `<form>` tag - which indicates that the error in the present (non-working) *meta-programming* example UrWeb-crudWidgetTxn1 is being caused by something *else*.

Thanks for any help getting the present, meta-programming version to compile using result type `transaction xml` for `Widget`.

###

