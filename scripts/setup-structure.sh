mkdir -p frontend/src/{components,pages,store,utils,services,hooks,types,assets,layouts}
mkdir -p frontend/src/components/{common,forms,ui}
mkdir -p frontend/src/pages/{auth,dashboard,courses,profile}
mkdir -p backend/{cmd,internal,pkg}
mkdir -p backend/internal/{handler,middleware,model,repository,service}
mkdir -p backend/ai_engine/{agents,memory,utils,config}
mkdir -p backend/ai_engine/agents/{coordinator,vision,conversation,memory}
mkdir -p backend/ai_engine/memory/{vector_store,embeddings}
touch backend/ai_engine/requirements.txt 