(* Notion API configuration: API url, export filename, Notion token v2, Notion
    space ID.

    TODO Do some smart constructing.
*)
type config = {
  api : string;
  export_filename : string;
  token_v2 : string;
  space_id : string;
}

let config =
  {
    api = "https://www.notion.so/api/v3";
    export_filename = "export.zip";
    token_v2 = Sys.getenv "NOTION_TOKEN_V2";
    space_id = Sys.getenv "NOTION_SPACE_ID";
  }
;;

print_endline config.token_v2
