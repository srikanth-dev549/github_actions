locals {
  json_data_7 = jsondecode(file("./data.json"))
}

locals {

  helper_list = flatten([for v in local.json_data_7.user_roles:
            [ for project, role in v:
            [ for roles, users in role:
            [ for i in users:
             { "project" = project
                "id" = "${project}-${roles}-${i}"
               "role" = roles
               "member" = i
              }
            ]
            ]
            ]
  ]
          )
}

resource "google_project_iam_member" "rolebinding" {
  for_each     = { for idx, v in local.helper_list: v.id => v }
  project = each.value.project
  role    = "roles/${each.value.role}"
  member  = each.value.member
  
}

  resource "null_resource" "display_message" {
  provisioner "local-exec" {
    command = "echo '##############APPLYING ONLY SERVICE ACCOUNTS AND USERS TO THE ROLES IN PROJECT LEVEL || ORG LEVEL POLICIES ARE OMITTED############################'"
  }
}
