#!/bin/bash

trap 'stop' SIGUSR1 SIGINT SIGHUP SIGQUIT SIGTERM SIGSTOP

REPO="github repo with ssh protocol"
SOURCEDIR="source code directory"
PROJECT="project name"

stop() {
        exit 0
}

helpmsg() {
        echo "Usage: $0 [option1] [option2]"
        echo ""
        echo "option1: [site]"
        echo "option2: [type]"
        echo ""
}

restart_lsyncd() {
        /usr/bin/systemctl restart lsyncd.service
}

prepare_pre_production(){
    cd $SOURCEDIR    
    /usr/bin/rm -rf $PROJECT_deploy
    /usr/bin/cp -rpv $SOURCEDIR/$PROJECT $SOURCEDIR/$PROJECT_deploy
}

update_pre_env() {
    cd $SOURCEDIR/$PROJECT_deploy
        
    read -n 1 -s -r -p " Please press any key to start editing .env.production ..."
    vim $SOURCEDIR/$PROJECT_deploy/.env.production
        
    sleep 1

    echo "\n"
    echo "Edit completed, beginning deploy ..."    
    
    /usr/bin/yarn frontend-cli build
    echo "Please check pre production web page."
}

update_pre_feature() {
        cd $SOURCEDIR/$PROJECT_deploy
        
        /usr/bin/git pull --rebase origin master
        /usr/bin/yarn install
        /usr/bin/yarn frontend-cli build

        echo "Please check pre production web page before deploy to production."
}

deploy_production() {
    cd $SOURCEDIR
        
    /usr/bin/rm -rf $PROJECT_bak

    echo "Rename the past version directory to _bak..."

    /bin/mv -v $SOURCEDIR/$PROJECT $SOURCEDIR/$PROJECT_bak
    
    echo ""
    echo "Starting deploy the currnet version code to production directory..."      
    
    /bin/mv -v $SOURCEDIR/$PROJECT_deploy $SOURCEDIR/$PROJECT
    /bin/cp -rp $SOURCEDIR/$PROJECT $SOURCEDIR/$PROJECT_deploy
        
    echo ""
    echo "All works done well."
}

rollback_pre_production() {
    cd $SOURCEDIR

    /usr/bin/rm -rf $PROJECT_deploy
    /usr/bin/cp -rp $SOURCEDIR/$PROJECT $SOURCEDIR/$PROJECT_deploy
    
    echo ""
    echo "Finished. Please check out the pre producyin pages again."
}

rollback_production() {
    echo "Rolling back the Previous version..."

    /bin/mv $SOURCEDIR/$PROJECT /tmp
    /bin/mv -v $SOURCEDIR/$PROJECT_bak $SOURCEDIR/$PROJECT
        
    echo ""
    echo "Finished. Please check out the web pages."
}

sync_core() {
    if [[ "f6" == "${SITE}" ]]; then

        if [[ "UPDATE_PRE_ENV" == "${SYNC_TYPE}" ]]; then
            echo ""
            prepare_pre_production
            update_pre_env

            elif [[ "UPDATE_PRE_FEATURE" == "${SYNC_TYPE}" ]]; then
            echo ""
            prepare_pre_production
            update_pre_feature

            elif [[ "DEPLOY_PRODUCTION" == "${SYNC_TYPE}" ]]; then
            echo ""
            deploy_production
            restart_lsyncd

            elif [[ "ROLLBACK_PREPRODUCTION" == "${SYNC_TYPE}" ]]; then
            echo ""
            rollback_pre_production

            elif [[ "ROLLBACK_PRODUCTION" == "${SYNC_TYPE}" ]]; then
            echo ""
            rollback_production
        fi
    fi
}

Rcmd() {
        cmdKey=$1
        shift
        cmdHost=$1
        shift
        ssh -i $cmdKey -2 -o ConnectTimeout=$TIME_RETRY root@$cmdHost "$@"
}

SYNC=0

for opt in $@
do
        case $opt in
        #site type
            project_name)
            SITE=project_name;;

        #sync type
            update_pre_env)
            SYNC_TYPE=UPDATE_PRE_ENV
            SYNC=1;;

            update_pre_feature)
            SYNC_TYPE=UPDATE_PRE_FEATURE
            SYNC=1;;

            deploy_production)
            SYNC_TYPE=DEPLOY_PRODUCTION
            SYNC=1;;

            rollback_preproduction)
            SYNC_TYPE=ROLLBACK_PREPRODUCTION
            SYNC=1;;
            
            rollback_production)
            SYNC_TYPE=ROLLBACK_PRODUCTION
            SYNC=1;;

            --help|-help|-h)
              helpmsg;;
        esac
done

if [[ 1 -eq ${SYNC} && ! -z ${SITE} && ! -z ${SYNC_TYPE} ]]; then
        sync_core
fi
