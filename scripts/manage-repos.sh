#!/bin/bash

# Snaproom Nested Repository Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository definitions
REPOS=(
    "snaproom-react:https://github.com/ryokushaka/snaproom-react.git"
    "snaproom-laravel:https://github.com/ryokushaka/snaproom-laravel.git"
    "snaproom-infrastructure:https://github.com/ryokushaka/snaproom-infrastructure.git"
)

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Snaproom Nested Repository Management"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  setup       Clone all service repositories"
    echo "  status      Show status of all repositories"
    echo "  pull        Pull latest changes for all repositories"
    echo "  push        Push changes for all repositories (with confirmation)"
    echo "  clean       Remove all nested repositories"
    echo "  branch      Show current branch for all repositories"
    echo "  checkout    Checkout branch for specific repository"
    echo ""
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 status"
    echo "  $0 pull"
    echo "  $0 checkout snaproom-react develop"
}

# Function to setup all repositories
setup_repos() {
    print_info "Setting up all service repositories..."
    
    for repo_info in "${REPOS[@]}"; do
        IFS=':' read -r repo_name repo_url <<< "$repo_info"
        
        if [ -d "$repo_name" ]; then
            print_warning "$repo_name already exists"
        else
            print_info "Cloning $repo_name..."
            git clone "$repo_url" "$repo_name"
            print_success "Cloned $repo_name"
        fi
    done
    
    print_success "All repositories set up successfully"
}

# Function to show repository status
show_status() {
    print_info "Repository status:"
    echo ""
    
    # Main repository status
    echo "=== Main Repository (snaproom) ==="
    git status --porcelain
    echo "Branch: $(git branch --show-current)"
    echo "Latest commit: $(git log -1 --oneline)"
    echo ""
    
    # Service repositories status
    for repo_info in "${REPOS[@]}"; do
        IFS=':' read -r repo_name repo_url <<< "$repo_info"
        
        if [ -d "$repo_name" ]; then
            echo "=== $repo_name ==="
            cd "$repo_name"
            git status --porcelain
            echo "Branch: $(git branch --show-current)"
            echo "Latest commit: $(git log -1 --oneline)"
            cd ..
            echo ""
        else
            print_warning "$repo_name not found (run 'setup' first)"
            echo ""
        fi
    done
}

# Function to pull all repositories
pull_repos() {
    print_info "Pulling latest changes for all repositories..."
    
    # Pull main repository
    print_info "Pulling main repository..."
    git pull
    
    # Pull service repositories
    for repo_info in "${REPOS[@]}"; do
        IFS=':' read -r repo_name repo_url <<< "$repo_info"
        
        if [ -d "$repo_name" ]; then
            print_info "Pulling $repo_name..."
            cd "$repo_name"
            git pull
            cd ..
            print_success "Pulled $repo_name"
        else
            print_warning "$repo_name not found"
        fi
    done
    
    print_success "All repositories updated"
}

# Function to push all repositories
push_repos() {
    print_warning "This will push changes for all repositories with uncommitted changes"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Pushing changes for all repositories..."
        
        # Check main repository
        if [ -n "$(git status --porcelain)" ]; then
            print_info "Pushing main repository..."
            git push
            print_success "Pushed main repository"
        fi
        
        # Check service repositories
        for repo_info in "${REPOS[@]}"; do
            IFS=':' read -r repo_name repo_url <<< "$repo_info"
            
            if [ -d "$repo_name" ]; then
                cd "$repo_name"
                if [ -n "$(git status --porcelain)" ]; then
                    print_info "Pushing $repo_name..."
                    git push
                    print_success "Pushed $repo_name"
                fi
                cd ..
            fi
        done
        
        print_success "All repositories pushed"
    else
        print_info "Push cancelled"
    fi
}

# Function to clean all repositories
clean_repos() {
    print_warning "This will remove all nested service repositories"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing all nested repositories..."
        
        for repo_info in "${REPOS[@]}"; do
            IFS=':' read -r repo_name repo_url <<< "$repo_info"
            
            if [ -d "$repo_name" ]; then
                rm -rf "$repo_name"
                print_success "Removed $repo_name"
            fi
        done
        
        print_success "All nested repositories removed"
    else
        print_info "Clean cancelled"
    fi
}

# Function to show branches
show_branches() {
    print_info "Current branches for all repositories:"
    echo ""
    
    # Main repository branch
    echo "=== Main Repository (snaproom) ==="
    echo "Current branch: $(git branch --show-current)"
    echo ""
    
    # Service repositories branches
    for repo_info in "${REPOS[@]}"; do
        IFS=':' read -r repo_name repo_url <<< "$repo_info"
        
        if [ -d "$repo_name" ]; then
            echo "=== $repo_name ==="
            cd "$repo_name"
            echo "Current branch: $(git branch --show-current)"
            git branch -a
            cd ..
            echo ""
        else
            print_warning "$repo_name not found"
            echo ""
        fi
    done
}

# Function to checkout branch for specific repository
checkout_branch() {
    local repo_name=$1
    local branch_name=$2
    
    if [ -z "$repo_name" ] || [ -z "$branch_name" ]; then
        print_error "Usage: $0 checkout <repository> <branch>"
        return 1
    fi
    
    if [ ! -d "$repo_name" ]; then
        print_error "Repository '$repo_name' not found"
        return 1
    fi
    
    print_info "Checking out '$branch_name' in '$repo_name'..."
    
    cd "$repo_name"
    git checkout "$branch_name"
    cd ..
    
    print_success "Checked out '$branch_name' in '$repo_name'"
}

# Main script logic
case "${1:-}" in
    setup)
        setup_repos
        ;;
    status)
        show_status
        ;;
    pull)
        pull_repos
        ;;
    push)
        push_repos
        ;;
    clean)
        clean_repos
        ;;
    branch)
        show_branches
        ;;
    checkout)
        checkout_branch "$2" "$3"
        ;;
    help|--help|-h)
        show_usage
        ;;
    "")
        print_error "No command specified"
        echo ""
        show_usage
        exit 1
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac