#!/bin/bash

# Snaproom Submodule Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo "Snaproom Submodule Management"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init        Initialize all submodules"
    echo "  update      Update all submodules to latest"
    echo "  status      Show status of all submodules"
    echo "  sync        Sync submodule URLs"
    echo "  pull        Pull latest changes for all submodules"
    echo "  checkout    Checkout specific branch/tag for submodule"
    echo "  reset       Reset submodules to committed state"
    echo ""
    echo "Examples:"
    echo "  $0 init"
    echo "  $0 update"
    echo "  $0 checkout services/frontend main"
    echo "  $0 status"
}

# Function to initialize submodules
init_submodules() {
    print_info "Initializing all submodules..."
    
    git submodule update --init --recursive
    
    print_success "All submodules initialized"
}

# Function to update submodules
update_submodules() {
    print_info "Updating all submodules to latest..."
    
    git submodule update --remote --recursive
    
    print_success "All submodules updated"
}

# Function to show submodule status
show_status() {
    print_info "Submodule status:"
    echo ""
    
    git submodule status --recursive
    
    echo ""
    print_info "Detailed status:"
    
    # Check each submodule
    for submodule in services/frontend services/backend infrastructure; do
        if [ -d "$submodule" ]; then
            echo ""
            echo "=== $submodule ==="
            cd "$submodule"
            echo "Branch: $(git branch --show-current)"
            echo "Latest commit: $(git log -1 --oneline)"
            echo "Status: $(git status --porcelain | wc -l | tr -d ' ') changes"
            cd - > /dev/null
        fi
    done
}

# Function to sync submodule URLs
sync_submodules() {
    print_info "Syncing submodule URLs..."
    
    git submodule sync --recursive
    
    print_success "Submodule URLs synced"
}

# Function to pull latest changes
pull_submodules() {
    print_info "Pulling latest changes for all submodules..."
    
    git submodule foreach --recursive git pull origin main
    
    print_success "All submodules pulled"
}

# Function to checkout specific branch/tag
checkout_submodule() {
    local submodule=$1
    local branch=$2
    
    if [ -z "$submodule" ] || [ -z "$branch" ]; then
        print_error "Usage: $0 checkout <submodule> <branch>"
        return 1
    fi
    
    if [ ! -d "$submodule" ]; then
        print_error "Submodule '$submodule' not found"
        return 1
    fi
    
    print_info "Checking out '$branch' in '$submodule'..."
    
    cd "$submodule"
    git checkout "$branch"
    cd - > /dev/null
    
    print_success "Checked out '$branch' in '$submodule'"
}

# Function to reset submodules
reset_submodules() {
    print_warning "This will reset all submodules to their committed state"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Resetting all submodules..."
        
        git submodule foreach --recursive git reset --hard HEAD
        git submodule update --init --recursive
        
        print_success "All submodules reset"
    else
        print_info "Reset cancelled"
    fi
}

# Main script logic
case "${1:-}" in
    init)
        init_submodules
        ;;
    update)
        update_submodules
        ;;
    status)
        show_status
        ;;
    sync)
        sync_submodules
        ;;
    pull)
        pull_submodules
        ;;
    checkout)
        checkout_submodule "$2" "$3"
        ;;
    reset)
        reset_submodules
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