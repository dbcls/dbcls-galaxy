<%inherit file="/base.mako"/>
<%namespace file="/message.mako" import="render_msg" />

## Render a row
<%def name="render_row( role, ctr, anchored, curr_anchor )">
    %if ctr % 2 == 1:
        <tr class="odd_row">
    %else:
        <tr>
    %endif
        <td>
            ${role.name}
            <a id="role-${role.id}-popup" class="popup-arrow" style="display: none;">&#9660;</a>
            <div popupmenu="role-${role.id}-popup">
                <a class="action-button" href="${h.url_for( action='undelete_role', role_id=role.id )}">Undelete</a>
                <a class="action-button" href="${h.url_for( action='purge_role', role_id=role.id )}">Purge</a>
            </div>
        </td>
        <td>${role.description}</td>
        <td>${role.type}</td>
        <td>
            ${len( role.users )}
        </td>
        <td>
            ${len( role.groups )}
            %if not anchored:
                <a name="${curr_anchor}"></a>
                <div style="float: right;"><a href="#TOP">top</a></div>
            %endif
        </td>
    </tr>
</%def>

<a name="TOP"><h2>Deleted Roles</h2></a>

%if msg:
    ${render_msg( msg, messagetype )}
%endif

%if len( roles ) == 0:
    There are no deleted Galaxy roles
%else:
    <table class="manage-table colored" border="0" cellspacing="0" cellpadding="0" width="100%">
        <% 
            render_quick_find = len( roles ) > 50
            ctr = 0
        %>
        %if render_quick_find:
            <%
                anchors = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z']
                anchor_loc = 0
                anchored = False
                curr_anchor = 'A'
            %>
            <tr style="background: #EEE">
                <td colspan="3" style="text-align: center; border-bottom: 1px solid #D8B365">
                    Jump to letter:
                    %for a in anchors:
                        | <a href="#${a}">${a}</a>
                    %endfor
                </td>
            </tr>
        %endif
        <tr class="header">
            <td>Name</td>
            <td>Description</td>
            <td>Type</td>
            <td>Users</td>
            <td>Groups</td>
        </tr>
        %for ctr, role in enumerate( roles ):
            %if render_quick_find and not role.name.upper().startswith( curr_anchor ):
                <% anchored = False %>
            %endif
            %if render_quick_find and role.name.upper().startswith( curr_anchor ):
                %if not anchored:
                    ${render_row( role, ctr, anchored, curr_anchor )}
                    <% anchored = True %>
                %else:
                    ${render_row( role, ctr, anchored, curr_anchor )}
                %endif
            %elif render_quick_find:
                %for anchor in anchors[ anchor_loc: ]:
                    %if role.name.upper().startswith( anchor ):
                        %if not anchored:
                            <% curr_anchor = anchor %>
                            ${render_row( role, ctr, anchored, curr_anchor )}
                            <%  anchored = True %>
                        %else:
                            ${render_row( role, ctr, anchored, curr_anchor )}
                        %endif
                        <% 
                            anchor_loc = anchors.index( anchor )
                            break 
                        %>
                    %endif
                %endfor
            %else:
                ${render_row( role, ctr, True, '' )}
            %endif
        %endfor
    </table>
%endif
