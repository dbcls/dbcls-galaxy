<% _=n_ %>
<%inherit file="/base.mako"/>
<%def name="title()">History options</%def>
    
<h2>${_('History Options')}</h2>

%if not user:
<div class="infomessage">
    <div>${_('You must be ')}<a target="galaxy_main" href="${h.url_for( controller='user', action='login' )}">${_('logged in')}</a>${_(' to store or switch histories.')}</div>
</div>
%endif

<ul>
%if user:
    <li><a href="${h.url_for( controller='history', action='rename', id=history.id )}" target="galaxy_main">Rename</a> current history (stored as "${history.name}")</li>
    <li><a href="${h.url_for( controller='history', action='list')}" target="galaxy_main">List</a> previously stored histories</li>
    %if len( history.active_datasets ) > 0:
        <li><a href="${h.url_for( controller='root', action='history_new' )}">Create</a> a new empty history</li>
    %endif
    <li><a href="${h.url_for( controller='workflow', action='build_from_current_history' )}">Construct workflow</a> from the current history</li>
    <li><a href="${h.url_for( controller='history', action='share' )}" target="galaxy_main">Share</a> current history</div>
    <li><a href="${h.url_for( action='history_set_default_permissions' )}">Change default permissions</a> for the current history</li>
%endif
    <li><a href="${h.url_for( controller='root', action='history', show_deleted=True)}" target="galaxy_history">Show deleted</a> datasets in history</li>
    <li><a href="${h.url_for( controller='history', action='delete_current' )}" confirm="Are you sure you want to delete the current history?">Delete</a> current history</div>
</ul>
