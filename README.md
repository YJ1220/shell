# 说明
## auto_deployment
简单的自动部署脚本

git pull
git diff
git checkout --track  origin/dev
if [  ${branch_name}   !=  'master'  ];then
    git checkout --track  origin/dev
fi



# 多分支部署
# 判断分支
if [  ${branch_name}   !=  'master'  ];then
    git pull origin ${branch_name}
fi
