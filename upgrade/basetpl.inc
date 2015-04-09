s/<\/head>/\
        \{\* jkuery enabled \*\} \
        \{include file='\/kbox\/samba\/jkuery\/www\/markers\/KGlobalPageHeader'\} \
        \{if \$kpage.body_id  eq "adminui"}\
                \{include file='\/kbox\/samba\/jkuery\/www\/markers\/KAdminPageHeader'\}\
        \{elseif \$kpage.body_id eq "systemui"}\
                 \{include file='\/kbox\/samba\/jkuery\/www\/markers\/KSysPageHeader'\}\
        \{elseif \$kpage.body_id eq "userui"}\
                \{include file='\/kbox\/samba\/jkuery\/www\/markers\/KUserPageHeader'\}\
        \{elseif \$kpage.body_id eq "welcome" }\
                \{include file='\/kbox\/samba\/jkuery\/www\/markers\/KWelcomePageHeader'\}\
        \{\/if\}\
        \{include file='\/kbox\/samba\/jkuery\/www\/2.3\/restorejQuery'\} \
        \{\* end jkuery enabled \*\} \
<\/head>/I